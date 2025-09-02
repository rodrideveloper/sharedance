import { Router } from 'express';
import * as admin from 'firebase-admin';
import { authenticateUser, requireAdmin } from '../middleware/validation';

const router = Router();
const db = admin.firestore();

// GET /api/reports - Get reports (admin or teacher's own reports)
router.get('/',
    authenticateUser,
    async (req, res): Promise<void> => {
        try {
            let query: any = db.collection('reports');

            if (req.user?.role === 'teacher') {
                query = query.where('professorId', '==', req.user.uid);
            } else if (req.user?.role !== 'admin') {
                res.status(403).json({ error: 'Unauthorized' });
                return;
            }

            const snapshot = await query.orderBy('createdAt', 'desc').get();
            const reports = snapshot.docs.map((doc: any) => ({
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
    async (req, res): Promise<void> => {
        try {
            const { month, professorId } = req.body; // Format: "2024-08"

            if (!month || !professorId) {
                res.status(400).json({ error: 'Month and professorId are required' });
                return;
            }

            const [year, monthNum] = month.split('-').map(Number);
            const startOfMonth = new Date(year, monthNum - 1, 1);
            const endOfMonth = new Date(year, monthNum, 0);

            // Get professor's classes
            const classesSnapshot = await db
                .collection('classes')
                .where('professorId', '==', professorId)
                .get();

            let totalStudents = 0;

            for (const classDoc of classesSnapshot.docs) {
                const classId = classDoc.id;

                // Count reservations for this class in the specified month
                const reservationsSnapshot = await db
                    .collection('reservations')
                    .where('classId', '==', classId)
                    .where('status', '==', 'completed')
                    .where('date', '>=', admin.firestore.Timestamp.fromDate(startOfMonth))
                    .where('date', '<=', admin.firestore.Timestamp.fromDate(endOfMonth))
                    .get();

                totalStudents += reservationsSnapshot.size;
            }

            // Calculate payment
            const amountToPay = totalStudents * 10;

            // Create report
            const reportRef = db.collection('reports').doc();
            await reportRef.set({
                reportId: reportRef.id,
                month: month,
                professorId: professorId,
                totalStudents: totalStudents,
                amountToPay: amountToPay,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            res.status(201).json({
                id: reportRef.id,
                message: 'Report generated successfully',
                data: {
                    month,
                    professorId,
                    totalStudents,
                    amountToPay
                }
            });

        } catch (error) {
            console.error('Error generating report:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

export default router;
