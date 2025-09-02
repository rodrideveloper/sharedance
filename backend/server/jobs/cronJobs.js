const cron = require('node-cron');
const admin = require('firebase-admin');

const db = admin.firestore();

// Clean up expired reservations - runs daily at 2 AM
cron.schedule('0 2 * * *', async () => {
    console.log('🧹 Running daily cleanup of expired reservations...');

    try {
        const now = admin.firestore.Timestamp.now();
        const oneDayAgo = admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 24 * 60 * 60 * 1000)
        );

        // Find expired reservations that are still pending
        const expiredReservations = await db
            .collection('reservations')
            .where('date', '<', oneDayAgo)
            .where('status', '==', 'confirmed')
            .get();

        const batch = db.batch();
        let count = 0;

        expiredReservations.docs.forEach(doc => {
            batch.update(doc.ref, {
                status: 'completed',
                updatedAt: now
            });
            count++;
        });

        if (count > 0) {
            await batch.commit();
            console.log(`✅ Updated ${count} expired reservations to completed`);
        } else {
            console.log('✅ No expired reservations found');
        }

    } catch (error) {
        console.error('❌ Error in daily cleanup:', error);
    }
});

// Generate daily reports - runs daily at 3 AM
cron.schedule('0 3 * * *', async () => {
    console.log('📊 Generating daily reports...');

    try {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        yesterday.setHours(0, 0, 0, 0);

        const today = new Date(yesterday);
        today.setDate(today.getDate() + 1);

        const startOfDay = admin.firestore.Timestamp.fromDate(yesterday);
        const endOfDay = admin.firestore.Timestamp.fromDate(today);

        // Get all completed reservations from yesterday
        const reservations = await db
            .collection('reservations')
            .where('date', '>=', startOfDay)
            .where('date', '<', endOfDay)
            .where('status', '==', 'completed')
            .get();

        // Group by professor
        const professorStats = {};

        reservations.docs.forEach(doc => {
            const data = doc.data();
            const professorId = data.professorId;

            if (!professorStats[professorId]) {
                professorStats[professorId] = {
                    totalClasses: 0,
                    totalEarnings: 0,
                    students: new Set()
                };
            }

            professorStats[professorId].totalClasses++;
            professorStats[professorId].totalEarnings += 10; // Assuming $10 per class
            professorStats[professorId].students.add(data.userId);
        });

        // Save daily reports for each professor
        const batch = db.batch();

        for (const [professorId, stats] of Object.entries(professorStats)) {
            const reportRef = db.collection('daily_reports').doc();
            batch.set(reportRef, {
                professorId,
                date: startOfDay,
                totalClasses: stats.totalClasses,
                totalEarnings: stats.totalEarnings,
                uniqueStudents: stats.students.size,
                generatedAt: admin.firestore.FieldValue.serverTimestamp(),
                type: 'daily'
            });
        }

        if (Object.keys(professorStats).length > 0) {
            await batch.commit();
            console.log(`✅ Generated daily reports for ${Object.keys(professorStats).length} professors`);
        } else {
            console.log('✅ No classes found for yesterday');
        }

    } catch (error) {
        console.error('❌ Error generating daily reports:', error);
    }
});

// Generate weekly reports - runs every Sunday at 1 AM
cron.schedule('0 1 * * 0', async () => {
    console.log('📈 Generating weekly reports...');

    try {
        const now = new Date();
        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

        const startOfWeek = admin.firestore.Timestamp.fromDate(weekAgo);
        const endOfWeek = admin.firestore.Timestamp.fromDate(now);

        // Get all professors
        const professors = await db
            .collection('users')
            .where('role', '==', 'teacher')
            .get();

        const batch = db.batch();

        for (const professorDoc of professors.docs) {
            const professorId = professorDoc.id;

            // Get week's reservations for this professor
            const reservations = await db
                .collection('reservations')
                .where('professorId', '==', professorId)
                .where('date', '>=', startOfWeek)
                .where('date', '<', endOfWeek)
                .where('status', '==', 'completed')
                .get();

            const totalClasses = reservations.size;
            const totalEarnings = totalClasses * 10;

            const studentsSet = new Set();
            reservations.docs.forEach(doc => {
                studentsSet.add(doc.data().userId);
            });

            const reportRef = db.collection('weekly_reports').doc();
            batch.set(reportRef, {
                professorId,
                weekStart: startOfWeek,
                weekEnd: endOfWeek,
                totalClasses,
                totalEarnings,
                uniqueStudents: studentsSet.size,
                generatedAt: admin.firestore.FieldValue.serverTimestamp(),
                type: 'weekly'
            });
        }

        await batch.commit();
        console.log(`✅ Generated weekly reports for ${professors.size} professors`);

    } catch (error) {
        console.error('❌ Error generating weekly reports:', error);
    }
});

// Monthly credit expiration check - runs on the 1st of every month at 1 AM
cron.schedule('0 1 1 * *', async () => {
    console.log('💳 Running monthly credit expiration check...');

    try {
        const now = new Date();
        const threeMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 3, now.getDate());

        // Find users who haven't used credits in 3 months
        const users = await db
            .collection('users')
            .where('role', '==', 'student')
            .get();

        const batch = db.batch();
        let expiredCount = 0;

        for (const userDoc of users.docs) {
            const userId = userDoc.id;
            const userData = userDoc.data();

            if (userData.credits > 0) {
                // Check last reservation
                const lastReservation = await db
                    .collection('reservations')
                    .where('userId', '==', userId)
                    .orderBy('createdAt', 'desc')
                    .limit(1)
                    .get();

                if (lastReservation.empty ||
                    lastReservation.docs[0].data().createdAt.toDate() < threeMonthsAgo) {

                    // Credits have expired
                    batch.update(userDoc.ref, {
                        credits: 0,
                        expiredCredits: userData.credits,
                        creditsExpiredAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    // Create notification
                    const notificationRef = db.collection('notifications').doc();
                    batch.set(notificationRef, {
                        userId,
                        title: 'Créditos Expirados',
                        body: `${userData.credits} créditos han expirado por inactividad`,
                        type: 'credit_expiration',
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    expiredCount++;
                }
            }
        }

        if (expiredCount > 0) {
            await batch.commit();
            console.log(`✅ Expired credits for ${expiredCount} inactive users`);
        } else {
            console.log('✅ No credits expired this month');
        }

    } catch (error) {
        console.error('❌ Error in credit expiration check:', error);
    }
});

console.log('🕒 Cron jobs initialized:');
console.log('  - Daily cleanup: 2:00 AM');
console.log('  - Daily reports: 3:00 AM');
console.log('  - Weekly reports: Sunday 1:00 AM');
console.log('  - Credit expiration: 1st of month 1:00 AM');

module.exports = {};
