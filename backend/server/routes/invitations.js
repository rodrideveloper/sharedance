const express = require('express');
const admin = require('firebase-admin');
const Joi = require('joi');
const EmailService = require('../services/emailService');

const router = express.Router();
const emailService = new EmailService();

// Validaciones con Joi
const invitationSchema = Joi.object({
    email: Joi.string().email().required(),
    role: Joi.string().valid('Profesor', 'Teacher', 'Administrador', 'Admin', 'Estudiante', 'Student').required(),
    customMessage: Joi.string().optional().allow(''),
    inviterName: Joi.string().optional().default('ShareDance Team')
});

// Middleware de autenticación
const authMiddleware = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];

        if (!token) {
            return res.status(401).json({ error: 'Token de autorización requerido' });
        }

        const decodedToken = await admin.auth().verifyIdToken(token);
        req.user = decodedToken;
        next();
    } catch (error) {
        console.error('Error de autenticación:', error);
        res.status(401).json({ error: 'Token inválido' });
    }
};

// Enviar invitación (flujo simplificado con creación automática de usuario)
router.post('/send', authMiddleware, async (req, res) => {
    try {
        const { error, value } = invitationSchema.validate(req.body);

        if (error) {
            return res.status(400).json({
                error: 'Datos de invitación inválidos',
                details: error.details
            });
        }

        const { email, role, customMessage, inviterName } = value;

        // Verificar si el usuario ya existe
        try {
            const existingUser = await admin.auth().getUserByEmail(email);
            return res.status(400).json({
                error: 'El usuario ya está registrado en el sistema'
            });
        } catch (authError) {
            // Si no encuentra el usuario, está bien, puede continuar
            if (authError.code !== 'auth/user-not-found') {
                throw authError;
            }
        }

        // Generar contraseña temporal
        const temporaryPassword = emailService.generateTemporaryPassword();

        // Crear usuario en Firebase Auth con contraseña temporal
        let newUser;
        try {
            newUser = await admin.auth().createUser({
                email: email.toLowerCase(),
                password: temporaryPassword,
                emailVerified: false
            });

            // Asignar rol como custom claim
            await admin.auth().setCustomUserClaims(newUser.uid, {
                role: role.toLowerCase()
            });

        } catch (createUserError) {
            console.error('Error creando usuario:', createUserError);
            return res.status(500).json({
                error: 'Error creando el usuario',
                details: createUserError.message
            });
        }

        // Crear documento de invitación en Firestore (ahora como registro de la acción)
        const db = admin.firestore();
        const invitationData = {
            email: email.toLowerCase(),
            role,
            customMessage: customMessage || '',
            inviterName: inviterName || req.user.name || 'ShareDance Team',
            inviterId: req.user.uid,
            status: 'completed', // Ya está completada automáticamente
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            userUid: newUser.uid, // Referencia al usuario creado
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        const invitationRef = await db.collection('invitations').add(invitationData);

        // Enviar email de bienvenida con credenciales
        const emailResult = await emailService.sendWelcomeEmail(
            email,
            role,
            temporaryPassword,
            inviterName || req.user.name || 'ShareDance Team'
        );

        if (!emailResult.success) {
            // Si falla el email, no eliminamos el usuario ya creado, pero registramos el error
            console.error('Error enviando email de bienvenida:', emailResult.error);
            
            // Actualizar invitación con el error del email
            await invitationRef.update({
                emailError: emailResult.error,
                emailSent: false
            });

            return res.status(500).json({
                error: 'Usuario creado correctamente, pero hubo un error enviando el email de bienvenida',
                details: emailResult.error,
                userCreated: true,
                userUid: newUser.uid
            });
        }

        // Actualizar con messageId del email
        await invitationRef.update({
            emailMessageId: emailResult.messageId,
            emailSent: true
        });

        res.status(201).json({
            message: 'Usuario creado y email de bienvenida enviado correctamente',
            invitationId: invitationRef.id,
            messageId: emailResult.messageId,
            userUid: newUser.uid,
            userCreated: true
        });

    } catch (error) {
        console.error('Error enviando invitación:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Obtener todas las invitaciones
router.get('/', authMiddleware, async (req, res) => {
    try {
        const { status, limit = 50, offset = 0 } = req.query;
        const db = admin.firestore();

        let query = db.collection('invitations')
            .orderBy('sentAt', 'desc')
            .limit(parseInt(limit))
            .offset(parseInt(offset));

        if (status && status !== 'all') {
            if (status === 'pending') {
                // Buscar por invitaciones que fallaron al enviar email
                query = query.where('emailSent', '==', false);
            } else if (status === 'completed') {
                query = query.where('status', '==', 'completed');
            }
        }

        const snapshot = await query.get();

        const invitations = [];
        snapshot.forEach(doc => {
            const data = doc.data();

            // Convertir Timestamps de Firebase a strings ISO
            let sentAt = null;
            let completedAt = null;

            if (data.sentAt) {
                sentAt = data.sentAt.toDate().toISOString();
            }

            if (data.completedAt) {
                completedAt = data.completedAt.toDate().toISOString();
            }

            invitations.push({
                id: doc.id,
                ...data,
                sentAt: sentAt,
                completedAt: completedAt,
                // Agregar campos calculados para compatibilidad con frontend
                expiresAt: null, // Ya no aplicable
                status: data.emailSent === false ? 'email_failed' : data.status
            });
        });

        // Obtener total count para paginación
        const totalSnapshot = await db.collection('invitations').get();
        const total = totalSnapshot.size;

        res.json({
            invitations,
            pagination: {
                total,
                limit: parseInt(limit),
                offset: parseInt(offset),
                hasMore: (parseInt(offset) + parseInt(limit)) < total
            }
        });

    } catch (error) {
        console.error('Error obteniendo invitaciones:', error);
        res.status(500).json({
            error: 'Error obteniendo invitaciones',
            details: error.message
        });
    }
});

// Reenviar email de bienvenida (solo si el email falló inicialmente)
router.post('/:id/resend', authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const db = admin.firestore();

        const invitationDoc = await db.collection('invitations').doc(id).get();

        if (!invitationDoc.exists) {
            return res.status(404).json({ error: 'Invitación no encontrada' });
        }

        const invitation = invitationDoc.data();

        if (invitation.status === 'completed' && invitation.emailSent) {
            return res.status(400).json({ 
                error: 'El email de bienvenida ya fue enviado correctamente' 
            });
        }

        if (!invitation.userUid) {
            return res.status(400).json({ 
                error: 'No se puede reenviar: usuario no fue creado correctamente' 
            });
        }

        // Obtener información del usuario para reenviar credenciales
        let user;
        try {
            user = await admin.auth().getUser(invitation.userUid);
        } catch (userError) {
            return res.status(404).json({ 
                error: 'Usuario asociado no encontrado',
                details: userError.message
            });
        }

        // Generar nueva contraseña temporal
        const temporaryPassword = emailService.generateTemporaryPassword();

        // Actualizar contraseña del usuario
        await admin.auth().updateUser(invitation.userUid, {
            password: temporaryPassword
        });

        // Reenviar email con la nueva contraseña
        const emailResult = await emailService.sendWelcomeEmail(
            invitation.email,
            invitation.role,
            temporaryPassword,
            invitation.inviterName
        );

        if (!emailResult.success) {
            return res.status(500).json({
                error: 'Error reenviando el email de bienvenida',
                details: emailResult.error
            });
        }

        // Actualizar datos de reenvío
        await invitationDoc.ref.update({
            lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
            resendCount: admin.firestore.FieldValue.increment(1),
            emailMessageId: emailResult.messageId,
            emailSent: true,
            emailError: admin.firestore.FieldValue.delete() // Limpiar error anterior
        });

        res.json({
            message: 'Email de bienvenida reenviado correctamente con nueva contraseña',
            messageId: emailResult.messageId
        });

    } catch (error) {
        console.error('Error reenviando invitación:', error);
        res.status(500).json({
            error: 'Error reenviando invitación',
            details: error.message
        });
    }
});

// Eliminar invitación
router.delete('/:id', authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const db = admin.firestore();

        const invitationDoc = await db.collection('invitations').doc(id).get();

        if (!invitationDoc.exists) {
            return res.status(404).json({ error: 'Invitación no encontrada' });
        }

        await invitationDoc.ref.delete();

        res.json({ message: 'Invitación eliminada correctamente' });

    } catch (error) {
        console.error('Error eliminando invitación:', error);
        res.status(500).json({
            error: 'Error eliminando invitación',
            details: error.message
        });
    }
});

// Verificar estado de invitación (ya no se usa para aceptar, solo para consultas)
router.post('/:id/accept', async (req, res) => {
    try {
        const { id } = req.params;

        const db = admin.firestore();
        const invitationDoc = await db.collection('invitations').doc(id).get();

        if (!invitationDoc.exists) {
            return res.status(404).json({ error: 'Invitación no encontrada' });
        }

        const invitation = invitationDoc.data();

        if (invitation.status === 'completed') {
            return res.json({
                message: 'El usuario ya fue creado automáticamente',
                status: 'completed',
                userUid: invitation.userUid,
                role: invitation.role
            });
        }

        // Esto no debería pasar con el nuevo flujo, pero por compatibilidad
        return res.status(400).json({ 
            error: 'Invitación en estado inválido',
            status: invitation.status 
        });

    } catch (error) {
        console.error('Error aceptando invitación:', error);
        res.status(500).json({
            error: 'Error aceptando invitación',
            details: error.message
        });
    }
});

// Obtener estadísticas de invitaciones
router.get('/stats', authMiddleware, async (req, res) => {
    try {
        const db = admin.firestore();
        const invitationsRef = db.collection('invitations');

        const [totalSnapshot, completedSnapshot, emailFailedSnapshot] = await Promise.all([
            invitationsRef.get(),
            invitationsRef.where('status', '==', 'completed').get(),
            invitationsRef.where('emailSent', '==', false).get()
        ]);

        const stats = {
            total: totalSnapshot.size,
            completed: completedSnapshot.size,
            emailFailed: emailFailedSnapshot.size,
            successRate: totalSnapshot.size > 0 ? 
                Math.round((completedSnapshot.size / totalSnapshot.size) * 100) : 0
        };

        res.json(stats);

    } catch (error) {
        console.error('Error obteniendo estadísticas:', error);
        res.status(500).json({
            error: 'Error obteniendo estadísticas',
            details: error.message
        });
    }
});

module.exports = router;
