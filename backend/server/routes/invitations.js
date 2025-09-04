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

// Enviar invitación
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

        // Crear documento de invitación en Firestore
        const db = admin.firestore();
        const invitationData = {
            email: email.toLowerCase(),
            role,
            customMessage: customMessage || '',
            inviterName: inviterName || req.user.name || 'ShareDance Team',
            inviterId: req.user.uid,
            status: 'pending',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 días
        };

        const invitationRef = await db.collection('invitations').add(invitationData);

        // Enviar email
        const emailResult = await emailService.sendInvitationEmail(
            email,
            role,
            inviterName || req.user.name || 'ShareDance Team',
            customMessage,
            invitationRef.id // Pasar el ID de la invitación
        );

        if (!emailResult.success) {
            // Si falla el email, eliminar la invitación
            await invitationRef.delete();
            return res.status(500).json({
                error: 'Error enviando la invitación por email',
                details: emailResult.error
            });
        }

        // Actualizar con messageId del email
        await invitationRef.update({
            emailMessageId: emailResult.messageId
        });

        res.status(201).json({
            message: 'Invitación enviada correctamente',
            invitationId: invitationRef.id,
            messageId: emailResult.messageId
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
            query = query.where('status', '==', status);
        }

        const snapshot = await query.get();

        const invitations = [];
        snapshot.forEach(doc => {
            const data = doc.data();

            // Convertir Timestamps de Firebase a strings ISO
            let sentAt = null;
            let expiresAt = null;

            if (data.sentAt) {
                sentAt = data.sentAt.toDate().toISOString();
            }

            if (data.expiresAt) {
                expiresAt = data.expiresAt.toDate().toISOString();
            }

            invitations.push({
                id: doc.id,
                ...data,
                sentAt: sentAt,
                expiresAt: expiresAt
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

// Reenviar invitación
router.post('/:id/resend', authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const db = admin.firestore();

        const invitationDoc = await db.collection('invitations').doc(id).get();

        if (!invitationDoc.exists) {
            return res.status(404).json({ error: 'Invitación no encontrada' });
        }

        const invitation = invitationDoc.data();

        if (invitation.status === 'accepted') {
            return res.status(400).json({ error: 'La invitación ya fue aceptada' });
        }

        // Verificar si no ha expirado (opcional, podríamos permitir reenvío de expiradas)
        if (invitation.expiresAt && invitation.expiresAt.toDate() < new Date()) {
            // Extender la expiración
            await invitationDoc.ref.update({
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
            });
        }

        // Reenviar email
        const emailResult = await emailService.sendInvitationEmail(
            invitation.email,
            invitation.role,
            invitation.inviterName,
            invitation.customMessage
        );

        if (!emailResult.success) {
            return res.status(500).json({
                error: 'Error reenviando la invitación',
                details: emailResult.error
            });
        }

        // Actualizar datos de reenvío
        await invitationDoc.ref.update({
            lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
            resendCount: admin.firestore.FieldValue.increment(1),
            emailMessageId: emailResult.messageId
        });

        res.json({
            message: 'Invitación reenviada correctamente',
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

// Aceptar invitación (para el frontend)
router.post('/:id/accept', async (req, res) => {
    try {
        const { id } = req.params;
        const { userUid } = req.body;

        if (!userUid) {
            return res.status(400).json({ error: 'UID de usuario requerido' });
        }

        const db = admin.firestore();
        const invitationDoc = await db.collection('invitations').doc(id).get();

        if (!invitationDoc.exists) {
            return res.status(404).json({ error: 'Invitación no encontrada' });
        }

        const invitation = invitationDoc.data();

        if (invitation.status === 'accepted') {
            return res.status(400).json({ error: 'La invitación ya fue aceptada' });
        }

        if (invitation.expiresAt && invitation.expiresAt.toDate() < new Date()) {
            return res.status(400).json({ error: 'La invitación ha expirado' });
        }

        // Actualizar invitación como aceptada
        await invitationDoc.ref.update({
            status: 'accepted',
            acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
            acceptedByUid: userUid
        });

        // Actualizar rol del usuario en Firebase Auth
        await admin.auth().setCustomUserClaims(userUid, {
            role: invitation.role.toLowerCase()
        });

        res.json({
            message: 'Invitación aceptada correctamente',
            role: invitation.role
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

        const [totalSnapshot, pendingSnapshot, acceptedSnapshot, expiredSnapshot] = await Promise.all([
            invitationsRef.get(),
            invitationsRef.where('status', '==', 'pending').get(),
            invitationsRef.where('status', '==', 'accepted').get(),
            invitationsRef.where('expiresAt', '<', new Date()).get()
        ]);

        const stats = {
            total: totalSnapshot.size,
            pending: pendingSnapshot.size,
            accepted: acceptedSnapshot.size,
            expired: expiredSnapshot.size,
            rejected: totalSnapshot.size - pendingSnapshot.size - acceptedSnapshot.size
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
