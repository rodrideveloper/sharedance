const express = require('express');
const admin = require('firebase-admin');
const { authenticateUser, requireAdmin } = require('../middleware/validation');

const router = express.Router();
const db = admin.firestore();

// GET /api/reports - Get reports (admin or teacher's own reports)
router.get('/',
    authenticateUser,
    async (req, res) => {
        try {
            let query = db.collection('reports');

            if (!req.user) {
                res.status(401).json({ error: 'Unauthorized' });
                return;
            }

            if (req.user.role === 'teacher') {
                query = query.where('professorId', '==', req.user.uid);
            } else if (req.user.role !== 'admin') {
                res.status(403).json({ error: 'Unauthorized' });
                return;
            }

            const snapshot = await query.orderBy('createdAt', 'desc').get();
            const reports = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));

            res.json(reports);

        } catch (error) {
            console.error('Error fetching reports:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

// POST /api/reports/generate - Manually generate report for a specific month
router.post('/generate',
    requireAdmin,
    async (req, res) => {
        try {
            const { month, professorId } = req.body; // Format: "2024-08"

            if (!month || !professorId) {
                res.status(400).json({ error: 'Month and professorId are required' });
                return;
            }

            const [year, monthNum] = month.split('-').map(Number);
            const startOfMonth = new Date(year, monthNum - 1, 1);
            const endOfMonth = new Date(year, monthNum, 0);

            // Get reservations for the month
            const reservations = await db
                .collection('reservations')
                .where('professorId', '==', professorId)
                .where('date', '>=', admin.firestore.Timestamp.fromDate(startOfMonth))
                .where('date', '<=', admin.firestore.Timestamp.fromDate(endOfMonth))
                .where('status', '==', 'completed')
                .get();

            // Calculate statistics
            const totalClasses = reservations.size;
            const totalEarnings = totalClasses * 10; // Assuming $10 per class

            const studentsSet = new Set();
            reservations.docs.forEach(doc => {
                studentsSet.add(doc.data().userId);
            });
            const uniqueStudents = studentsSet.size;

            // Create report
            const reportRef = db.collection('reports').doc();
            await reportRef.set({
                professorId,
                month,
                year,
                monthNumber: monthNum,
                totalClasses,
                totalEarnings,
                uniqueStudents,
                generatedAt: admin.firestore.FieldValue.serverTimestamp(),
                generatedBy: req.user.uid,
                type: 'monthly'
            });

            res.status(201).json({
                id: reportRef.id,
                message: 'Report generated successfully',
                data: {
                    totalClasses,
                    totalEarnings,
                    uniqueStudents
                }
            });

        } catch (error) {
            console.error('Error generating report:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

module.exports = router;
