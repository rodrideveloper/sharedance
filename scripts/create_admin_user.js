const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp({
    credential: admin.credential.applicationDefault()
});

async function createAdminUser() {
    try {
        console.log('🔐 Creating admin user in Firebase Authentication...');
        
        // Create user in Firebase Authentication
        const userRecord = await admin.auth().createUser({
            email: 'admin@sharedance.com',
            password: '123456',
            displayName: 'Admin Usuario',
            emailVerified: true,
            disabled: false,
        });

        console.log('✅ Successfully created admin user:', userRecord.uid);
        
        // Set custom claims for admin role
        await admin.auth().setCustomUserClaims(userRecord.uid, {
            role: 'admin',
            temporaryPassword: false
        });
        
        console.log('✅ Set admin role custom claims');

        // Also create/update the user document in Firestore
        const db = admin.firestore();
        await db.collection('users').doc(userRecord.uid).set({
            id: userRecord.uid,
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

        console.log('✅ Created user document in Firestore');
        console.log('🎉 Admin user setup complete!');
        console.log('📧 Email: admin@sharedance.com');
        console.log('🔒 Password: 123456');
        
    } catch (error) {
        if (error.code === 'auth/email-already-exists') {
            console.log('⚠️  User already exists, updating custom claims...');
            const userRecord = await admin.auth().getUserByEmail('admin@sharedance.com');
            await admin.auth().setCustomUserClaims(userRecord.uid, {
                role: 'admin',
                temporaryPassword: false
            });
            console.log('✅ Updated admin role custom claims');
            console.log('📧 Email: admin@sharedance.com');
            console.log('🔒 Password: (existing password)');
        } else {
            console.error('❌ Error creating admin user:', error);
        }
    }
}

createAdminUser().then(() => {
    console.log('🏁 Script completed');
    process.exit(0);
}).catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
});
