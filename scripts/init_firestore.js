const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You'll need to download the service account key for each environment
// and set the GOOGLE_APPLICATION_CREDENTIALS environment variable

async function initializeFirestore() {
    const db = admin.firestore();

    console.log('🔥 Initializing Firestore collections...');

    try {
        // Create collections with initial dummy data to establish the structure

        // 1. Users collection (with indexes)
        console.log('📝 Creating users collection...');
        const usersRef = db.collection('users');

        // Create sample admin user
        await usersRef.doc('admin_sample').set({
            id: 'admin_sample',
            email: 'admin@sharedance.com',
            name: 'Admin Usuario',
            phone: '+1234567890',
            role: 'admin',
            isActive: true,
            profileImageUrl: null,
            credits: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Create sample teacher user
        await usersRef.doc('teacher_sample').set({
            id: 'teacher_sample',
            email: 'teacher@sharedance.com',
            name: 'Profesor Ejemplo',
            phone: '+1234567891',
            role: 'teacher',
            isActive: true,
            profileImageUrl: null,
            credits: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Create sample student user
        await usersRef.doc('student_sample').set({
            id: 'student_sample',
            email: 'student@sharedance.com',
            name: 'Estudiante Ejemplo',
            phone: '+1234567892',
            role: 'student',
            isActive: true,
            profileImageUrl: null,
            credits: 10,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 2. Classes collection
        console.log('💃 Creating classes collection...');
        const classesRef = db.collection('classes');

        await classesRef.doc('class_sample').set({
            id: 'class_sample',
            name: 'Salsa Principiantes',
            description: 'Clase de salsa para principiantes. Aprende los pasos básicos.',
            professorId: 'teacher_sample',
            professorName: 'Profesor Ejemplo',
            duration: 60, // minutes
            maxStudents: 15,
            price: 20.0,
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 3. Schedules collection
        console.log('📅 Creating schedules collection...');
        const schedulesRef = db.collection('schedules');

        await schedulesRef.doc('schedule_sample').set({
            id: 'schedule_sample',
            classId: 'class_sample',
            className: 'Salsa Principiantes',
            professorId: 'teacher_sample',
            professorName: 'Profesor Ejemplo',
            dayOfWeek: 'monday',
            startTime: '19:00',
            endTime: '20:00',
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 4. Reservations collection
        console.log('🎫 Creating reservations collection...');
        const reservationsRef = db.collection('reservations');

        // Create a future date for the sample reservation
        const futureDate = new Date();
        futureDate.setDate(futureDate.getDate() + 7); // Next week

        await reservationsRef.doc('reservation_sample').set({
            id: 'reservation_sample',
            userId: 'student_sample',
            userName: 'Estudiante Ejemplo',
            classId: 'class_sample',
            className: 'Salsa Principiantes',
            professorId: 'teacher_sample',
            professorName: 'Profesor Ejemplo',
            date: admin.firestore.Timestamp.fromDate(futureDate),
            status: 'confirmed',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 5. Payments collection
        console.log('💳 Creating payments collection...');
        const paymentsRef = db.collection('payments');

        await paymentsRef.doc('payment_sample').set({
            id: 'payment_sample',
            userId: 'student_sample',
            userName: 'Estudiante Ejemplo',
            amount: 100.0,
            credits: 5,
            paymentMethod: 'credit_card',
            status: 'completed',
            transactionId: 'tx_sample_123',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 6. Reports collection
        console.log('📊 Creating reports collection...');
        const reportsRef = db.collection('reports');

        await reportsRef.doc('report_sample').set({
            reportId: 'report_sample',
            month: '2024-08',
            professorId: 'teacher_sample',
            totalStudents: 25,
            amountToPay: 250.0,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 7. Notifications collection
        console.log('🔔 Creating notifications collection...');
        const notificationsRef = db.collection('notifications');

        await notificationsRef.doc('notification_sample').set({
            userId: 'student_sample',
            title: 'Recordatorio de clase',
            body: 'Tienes clase de Salsa Principiantes mañana a las 19:00',
            type: 'reminder',
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log('✅ Firestore collections initialized successfully!');
        console.log('');
        console.log('📋 Collections created:');
        console.log('  - users (with admin, teacher, and student samples)');
        console.log('  - classes (with sample class)');
        console.log('  - schedules (with sample schedule)');
        console.log('  - reservations (with sample reservation)');
        console.log('  - payments (with sample payment)');
        console.log('  - reports (with sample report)');
        console.log('  - notifications (with sample notification)');
        console.log('');
        console.log('🔍 Next steps:');
        console.log('  1. Set up Firestore indexes');
        console.log('  2. Configure security rules');
        console.log('  3. Enable Authentication');
        console.log('  4. Enable Storage');
        console.log('  5. Enable Cloud Messaging');

    } catch (error) {
        console.error('❌ Error initializing Firestore:', error);
        throw error;
    }
}

// Export for use in other scripts
module.exports = { initializeFirestore };

// Run if called directly
if (require.main === module) {
    const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

    if (!serviceAccountPath) {
        console.error('❌ Please set GOOGLE_APPLICATION_CREDENTIALS environment variable');
        console.log('Download the service account key from Firebase Console and set:');
        console.log('export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"');
        process.exit(1);
    }

    // Initialize admin SDK with service account
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });

    initializeFirestore()
        .then(() => {
            console.log('🎉 Initialization completed!');
            process.exit(0);
        })
        .catch((error) => {
            console.error('💥 Initialization failed:', error);
            process.exit(1);
        });
}
