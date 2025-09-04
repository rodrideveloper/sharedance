const admin = require('firebase-admin');

// Función para inicializar la colección de invitaciones en producción
async function createInvitationsCollection() {
    try {
        console.log('🔥 Inicializando colección de invitaciones en Firebase...');

        // Verificar que Firebase Admin esté inicializado
        if (!admin.apps.length) {
            console.error('❌ Firebase Admin no está inicializado');
            console.log('💡 Asegúrate de ejecutar: export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccount.json"');
            process.exit(1);
        }

        const db = admin.firestore();

        // Verificar si la colección ya existe
        const existingInvitations = await db.collection('invitations').limit(1).get();

        if (!existingInvitations.empty) {
            console.log('✅ La colección de invitaciones ya existe');
            console.log(`📊 Documentos encontrados: ${existingInvitations.size}`);
            return;
        }

        // Crear documento de ejemplo (se eliminará después)
        const sampleInvitation = {
            email: 'example@temp.com',
            role: 'student',
            customMessage: 'Documento temporal para inicializar la colección',
            inviterName: 'Sistema ShareDance',
            inviterId: 'system',
            status: 'pending',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 días
            userCreated: false,
            credentialsSent: false,
            isTemporary: true
        };

        console.log('📝 Creando documento temporal para inicializar la colección...');
        const docRef = await db.collection('invitations').add(sampleInvitation);
        console.log(`✅ Documento temporal creado con ID: ${docRef.id}`);

        // Eliminar el documento temporal inmediatamente
        await docRef.delete();
        console.log('🗑️  Documento temporal eliminado');

        console.log('🎉 Colección de invitaciones inicializada correctamente');
        console.log('📊 La colección está lista para recibir datos reales');

    } catch (error) {
        console.error('❌ Error inicializando la colección de invitaciones:', error);
        process.exit(1);
    }
}

// Verificar argumentos y ejecutar
if (process.argv.length < 3) {
    console.log('📋 Uso: node create_invitations_collection.js <environment>');
    console.log('💡 Environments: staging | production');
    process.exit(1);
}

const environment = process.argv[2];
if (!['staging', 'production'].includes(environment)) {
    console.error('❌ Environment debe ser "staging" o "production"');
    process.exit(1);
}

console.log(`🚀 Inicializando para environment: ${environment}`);

// Configurar path del service account según el environment
const serviceAccountPath = environment === 'production'
    ? './server/serviceAccount-production.json'
    : './server/serviceAccount-staging.json';

try {
    const serviceAccount = require(serviceAccountPath);

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
    });

    console.log(`✅ Firebase inicializado para ${environment}`);
    createInvitationsCollection();

} catch (error) {
    console.error(`❌ Error cargando service account desde ${serviceAccountPath}:`, error.message);
    console.log('💡 Asegúrate de que el archivo existe y tiene los permisos correctos');
    process.exit(1);
}
