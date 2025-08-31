const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();

// POST /api/webhooks/payment - Handle payment webhooks
router.post('/payment', async (req, res) => {
    try {
        const { type, data } = req.body;

        console.log('Payment webhook received:', { type, data });

        switch (type) {
            case 'payment.created':
            case 'payment.approved':
                await handlePaymentApproved(data);
                break;

            case 'payment.cancelled':
            case 'payment.rejected':
                await handlePaymentRejected(data);
                break;

            default:
                console.log('Unknown payment webhook type:', type);
        }

        res.status(200).json({ message: 'Webhook processed successfully' });

    } catch (error) {
        console.error('Error processing payment webhook:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/webhooks/class-reminder - Handle class reminders
router.post('/class-reminder', async (req, res) => {
    try {
        const { classId, message } = req.body;

        if (!classId) {
            return res.status(400).json({ error: 'classId is required' });
        }

        // Get reservations for the class
        const reservations = await db
            .collection('reservations')
            .where('classId', '==', classId)
            .where('status', '==', 'confirmed')
            .get();

        // Send notifications to all students
        const notificationPromises = reservations.docs.map(async (doc) => {
            const reservation = doc.data();
            const notificationRef = db.collection('notifications').doc();

            return notificationRef.set({
                userId: reservation.userId,
                title: 'Recordatorio de Clase',
                body: message || 'Tu clase comienza pronto',
                type: 'class_reminder',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await Promise.all(notificationPromises);

        res.status(200).json({
            message: 'Class reminders sent successfully',
            sentTo: reservations.size
        });

    } catch (error) {
        console.error('Error sending class reminders:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Helper functions
async function handlePaymentApproved(paymentData) {
    try {
        const { userId, amount, creditsToAdd } = paymentData;

        if (!userId || !creditsToAdd) {
            console.error('Invalid payment data:', paymentData);
            return;
        }

        // Add credits to user
        const userRef = db.collection('users').doc(userId);
        const userDoc = await userRef.get();

        if (userDoc.exists) {
            const currentCredits = userDoc.data().credits || 0;
            await userRef.update({
                credits: currentCredits + creditsToAdd,
                lastPayment: {
                    amount,
                    creditsAdded: creditsToAdd,
                    date: admin.firestore.FieldValue.serverTimestamp()
                }
            });

            // Create notification
            const notificationRef = db.collection('notifications').doc();
            await notificationRef.set({
                userId,
                title: 'Pago Procesado',
                body: `Se han agregado ${creditsToAdd} créditos a tu cuenta`,
                type: 'payment_success',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            console.log(`Added ${creditsToAdd} credits to user ${userId}`);
        }

    } catch (error) {
        console.error('Error handling payment approval:', error);
    }
}

async function handlePaymentRejected(paymentData) {
    try {
        const { userId, reason } = paymentData;

        if (!userId) {
            console.error('Invalid payment data:', paymentData);
            return;
        }

        // Create notification about failed payment
        const notificationRef = db.collection('notifications').doc();
        await notificationRef.set({
            userId,
            title: 'Pago Rechazado',
            body: `Tu pago no pudo ser procesado. ${reason || 'Intenta nuevamente.'}`,
            type: 'payment_failed',
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`Payment rejected for user ${userId}: ${reason}`);

    } catch (error) {
        console.error('Error handling payment rejection:', error);
    }
}

module.exports = router;
