const express = require('express');
const admin = require('firebase-admin');
const { authenticateUser } = require('../middleware/validation');

const router = express.Router();
const db = admin.firestore();

// GET /api/notifications - Get user's notifications
router.get('/',
    authenticateUser,
    async (req, res) => {
        try {
            const { unreadOnly } = req.query;

            if (!req.user) {
                res.status(401).json({ error: 'Unauthorized' });
                return;
            }

            let query = db.collection('notifications')
                .where('userId', '==', req.user.uid);

            if (unreadOnly === 'true') {
                query = query.where('isRead', '==', false);
            }

            const snapshot = await query
                .orderBy('createdAt', 'desc')
                .limit(50)
                .get();

            const notifications = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));

            res.json(notifications);

        } catch (error) {
            console.error('Error fetching notifications:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

// PUT /api/notifications/:id/read - Mark notification as read
router.put('/:id/read',
    authenticateUser,
    async (req, res) => {
        try {
            const { id } = req.params;

            if (!req.user) {
                res.status(401).json({ error: 'Unauthorized' });
                return;
            }

            const notificationRef = db.collection('notifications').doc(id);
            const notificationDoc = await notificationRef.get();

            if (!notificationDoc.exists) {
                res.status(404).json({ error: 'Notification not found' });
                return;
            }

            const notificationData = notificationDoc.data();

            if (notificationData.userId !== req.user.uid) {
                res.status(403).json({ error: 'Unauthorized' });
                return;
            }

            await notificationRef.update({
                isRead: true,
                readAt: admin.firestore.FieldValue.serverTimestamp()
            });

            res.json({ message: 'Notification marked as read' });

        } catch (error) {
            console.error('Error updating notification:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

// POST /api/notifications - Create notification (admin only)
router.post('/',
    authenticateUser,
    async (req, res) => {
        try {
            const { userId, title, body, type } = req.body;

            if (!req.user || req.user.role !== 'admin') {
                res.status(403).json({ error: 'Admin access required' });
                return;
            }

            if (!userId || !title || !body) {
                res.status(400).json({ error: 'userId, title, and body are required' });
                return;
            }

            const notificationRef = db.collection('notifications').doc();
            await notificationRef.set({
                userId,
                title,
                body,
                type: type || 'general',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            res.status(201).json({
                id: notificationRef.id,
                message: 'Notification created successfully'
            });

        } catch (error) {
            console.error('Error creating notification:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

module.exports = router;
