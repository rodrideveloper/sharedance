const express = require('express');
const admin = require('firebase-admin');
const { authenticateUser, requireAdmin, validateRequest } = require('../middleware/validation');

const router = express.Router();
const db = admin.firestore();

// Validation schemas
const createReservationSchema = {
    classId: { type: 'string', required: true },
    userId: { type: 'string', required: true },
    date: { type: 'string', required: true }
};

const updateReservationSchema = {
    status: { type: 'string', required: true, enum: ['confirmed', 'cancelled', 'completed'] }
};

// POST /api/reservations - Create reservation with validation
router.post('/',
    authenticateUser,
    validateRequest(createReservationSchema),
    async (req, res) => {
        try {
            const { classId, date, userId } = req.body;

            // Validate that the authenticated user is creating their own reservation
            if (!req.user || (req.user.uid !== userId && req.user.role !== 'admin')) {
                res.status(403).json({ error: 'Unauthorized' });
                return;
            }

            // Get class information
            const classDoc = await db.collection('classes').doc(classId).get();
            if (!classDoc.exists) {
                res.status(404).json({ error: 'Class not found' });
                return;
            }

            const classData = classDoc.data();

            // Check if class is active
            if (!classData.isActive) {
                res.status(400).json({ error: 'Class is not active' });
                return;
            }

            // Count existing reservations for this class and date
            const reservationDate = new Date(date);
            const existingReservations = await db
                .collection('reservations')
                .where('classId', '==', classId)
                .where('date', '==', admin.firestore.Timestamp.fromDate(reservationDate))
                .where('status', '==', 'confirmed')
                .get();

            // Check capacity
            if (existingReservations.size >= classData.maxStudents) {
                res.status(400).json({ error: 'Class is full' });
                return;
            }

            // Check if user has enough credits
            const userDoc = await db.collection('users').doc(userId).get();
            if (!userDoc.exists) {
                res.status(404).json({ error: 'User not found' });
                return;
            }

            const userData = userDoc.data();
            if (userData.credits < 1) {
                res.status(400).json({ error: 'Insufficient credits' });
                return;
            }

            // Check if user already has a reservation for the same time slot
            const userReservations = await db
                .collection('reservations')
                .where('userId', '==', userId)
                .where('date', '==', admin.firestore.Timestamp.fromDate(reservationDate))
                .where('status', '==', 'confirmed')
                .get();

            if (userReservations.size > 0) {
                res.status(400).json({ error: 'User already has a reservation for this time slot' });
                return;
            }

            // Create reservation in transaction
            const reservationRef = db.collection('reservations').doc();

            await db.runTransaction(async (transaction) => {
                // Create reservation
                transaction.set(reservationRef, {
                    classId,
                    userId,
                    professorId: classData.professorId,
                    date: admin.firestore.Timestamp.fromDate(reservationDate),
                    status: 'confirmed',
                    creditsUsed: 1,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // Deduct credit from user
                const userRef = db.collection('users').doc(userId);
                transaction.update(userRef, {
                    credits: userData.credits - 1
                });
            });

            res.status(201).json({
                id: reservationRef.id,
                message: 'Reservation created successfully'
            });

        } catch (error) {
            console.error('Error creating reservation:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

// PUT /api/reservations/:id - Update reservation status
router.put('/:id',
    authenticateUser,
    validateRequest(updateReservationSchema),
    async (req, res) => {
        try {
            const { id } = req.params;
            const { status } = req.body;

            const reservationRef = db.collection('reservations').doc(id);
            const reservationDoc = await reservationRef.get();

            if (!reservationDoc.exists) {
                res.status(404).json({ error: 'Reservation not found' });
                return;
            }

            const reservationData = reservationDoc.data();

            // Check authorization
            if (!req.user) {
                res.status(401).json({ error: 'Unauthorized' });
                return;
            }

            const canUpdate = req.user.role === 'admin' ||
                reservationData.userId === req.user.uid ||
                reservationData.professorId === req.user.uid;

            if (!canUpdate) {
                res.status(403).json({ error: 'Unauthorized' });
                return;
            }

            // Handle cancellation logic
            if (status === 'cancelled' && reservationData.status !== 'cancelled') {
                const classDate = reservationData.date.toDate();
                const now = new Date();
                const hoursDifference = (classDate.getTime() - now.getTime()) / (1000 * 60 * 60);

                // Only refund if cancelled more than 2 hours before class
                if (hoursDifference >= 2) {
                    await db.runTransaction(async (transaction) => {
                        // Update reservation status
                        transaction.update(reservationRef, {
                            status: 'cancelled',
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        });

                        // Refund credit to user
                        const userRef = db.collection('users').doc(reservationData.userId);
                        const userDoc = await transaction.get(userRef);
                        if (userDoc.exists) {
                            const userData = userDoc.data();
                            transaction.update(userRef, {
                                credits: userData.credits + 1
                            });
                        }
                    });

                    res.json({ message: 'Reservation cancelled and credit refunded' });
                    return;
                } else {
                    await reservationRef.update({
                        status: 'cancelled',
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    res.json({ message: 'Reservation cancelled (no refund - too close to class time)' });
                    return;
                }
            }

            // Regular status update
            await reservationRef.update({
                status,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            res.json({ message: 'Reservation updated successfully' });

        } catch (error) {
            console.error('Error updating reservation:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

// GET /api/reservations - Get user's reservations
router.get('/',
    authenticateUser,
    async (req, res) => {
        try {
            let query = db.collection('reservations');

            if (!req.user) {
                res.status(401).json({ error: 'Unauthorized' });
                return;
            }

            if (req.user.role === 'student') {
                query = query.where('userId', '==', req.user.uid);
            } else if (req.user.role === 'teacher') {
                query = query.where('professorId', '==', req.user.uid);
            }
            // Admins can see all reservations

            const snapshot = await query.orderBy('date', 'desc').get();
            const reservations = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));

            res.json(reservations);

        } catch (error) {
            console.error('Error fetching reservations:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

module.exports = router;
