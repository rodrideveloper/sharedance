coconst EmailService = require('../services/emailService');st express = require('express');
const Joi = require('joi');
const emailService = require('../services/emailService');
const admin = require('firebase-admin');

const router = express.Router();

// Esquema de validación para invitaciones
const invitationSchema = Joi.object({
    email: Joi.string().email().required(),
    role: Joi.string().valid('teacher', 'admin', 'student').required(),
    customMessage: Joi.string().max(500).optional().allow('')
});

// Middleware para verificar autenticación
const authenticateUser = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'Token de autorización requerido'
            });
        }

        const token = authHeader.split('Bearer ')[1];
        const decodedToken = await admin.auth().verifyIdToken(token);
        req.user = decodedToken;
        next();
    } catch (error) {
        console.error('Error verificando token:', error);
        res.status(401).json({
            success: false,
            message: 'Token inválido'
        });
    }
};

// Middleware para verificar permisos de admin
const requireAdmin = async (req, res, next) => {
    try {
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(req.user.uid)
            .get();

        if (!userDoc.exists) {
            return res.status(404).json({
                success: false,
                message: 'Usuario no encontrado'
            });
        }

        const userData = userDoc.data();
        if (userData.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Permisos insuficientes. Solo administradores pueden enviar invitaciones.'
            });
        }

        req.userRole = userData.role;
        req.userName = userData.name || userData.email;
        next();
    } catch (error) {
        console.error('Error verificando permisos:', error);
        res.status(500).json({
            success: false,
            message: 'Error verificando permisos'
        });
    }
};

// POST /api/invitations/send
router.post('/send', authenticateUser, requireAdmin, async (req, res) => {
    try {
        // Validar datos de entrada
        const { error, value } = invitationSchema.validate(req.body);
        if (error) {
            return res.status(400).json({
                success: false,
                message: 'Datos inválidos',
                errors: error.details.map(detail => detail.message)
            });
        }

        const { email, role, customMessage } = value;

        // Verificar si el usuario ya existe
        try {
            const existingUser = await admin.auth().getUserByEmail(email);
            if (existingUser) {
                return res.status(409).json({
                    success: false,
                    message: 'El usuario ya está registrado en el sistema'
                });
            }
        } catch (authError) {
            // Usuario no existe, podemos continuar
            if (authError.code !== 'auth/user-not-found') {
                throw authError;
            }
        }

        // Verificar si ya existe una invitación pendiente
        const existingInvitation = await admin.firestore()
            .collection('invitations')
            .where('email', '==', email)
            .where('status', '==', 'pending')
            .get();

        if (!existingInvitation.empty) {
            return res.status(409).json({
                success: false,
                message: 'Ya existe una invitación pendiente para este email'
            });
        }

        // Crear invitación en Firestore
        const invitationData = {
            email: email,
            role: role,
            customMessage: customMessage || '',
            invitedBy: req.user.uid,
            inviterName: req.userName,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 días
        };

        const invitationRef = await admin.firestore()
            .collection('invitations')
            .add(invitationData);

        // Enviar email
        const emailResult = await emailService.sendInvitationEmail(
            email,
            role,
            req.userName,
            customMessage
        );

        if (!emailResult.success) {
            // Si falla el email, eliminar la invitación
            await invitationRef.delete();
            return res.status(500).json({
                success: false,
                message: 'Error enviando el email de invitación',
                error: emailResult.error
            });
        }

        // Actualizar invitación con ID del email
        await invitationRef.update({
            emailMessageId: emailResult.messageId,
            emailSentAt: admin.firestore.FieldValue.serverTimestamp()
        });

        res.status(201).json({
            success: true,
            message: 'Invitación enviada correctamente',
            data: {
                invitationId: invitationRef.id,
                email: email,
                role: role,
                messageId: emailResult.messageId
            }
        });

    } catch (error) {
        console.error('Error enviando invitación:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno del servidor',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// GET /api/invitations
router.get('/', authenticateUser, requireAdmin, async (req, res) => {
    try {
        const { status, limit = 50, offset = 0 } = req.query;

        let query = admin.firestore()
            .collection('invitations')
            .orderBy('createdAt', 'desc');

        if (status) {
            query = query.where('status', '==', status);
        }

        const snapshot = await query
            .limit(parseInt(limit))
            .offset(parseInt(offset))
            .get();

        const invitations = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            invitations.push({
                id: doc.id,
                ...data,
                createdAt: data.createdAt?.toDate(),
                expiresAt: data.expiresAt?.toDate(),
                emailSentAt: data.emailSentAt?.toDate()
            });
        });

        res.json({
            success: true,
            data: invitations,
            pagination: {
                limit: parseInt(limit),
                offset: parseInt(offset),
                count: invitations.length
            }
        });

    } catch (error) {
        console.error('Error obteniendo invitaciones:', error);
        res.status(500).json({
            success: false,
            message: 'Error obteniendo invitaciones'
        });
    }
});

// DELETE /api/invitations/:id
router.delete('/:id', authenticateUser, requireAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        const invitationRef = admin.firestore().collection('invitations').doc(id);
        const invitationDoc = await invitationRef.get();

        if (!invitationDoc.exists) {
            return res.status(404).json({
                success: false,
                message: 'Invitación no encontrada'
            });
        }

        await invitationRef.update({
            status: 'cancelled',
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            cancelledBy: req.user.uid
        });

        res.json({
            success: true,
            message: 'Invitación cancelada'
        });

    } catch (error) {
        console.error('Error cancelando invitación:', error);
        res.status(500).json({
            success: false,
            message: 'Error cancelando invitación'
        });
    }
});

// POST /api/invitations/:id/resend
router.post('/:id/resend', authenticateUser, requireAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        const invitationRef = admin.firestore().collection('invitations').doc(id);
        const invitationDoc = await invitationRef.get();

        if (!invitationDoc.exists) {
            return res.status(404).json({
                success: false,
                message: 'Invitación no encontrada'
            });
        }

        const invitationData = invitationDoc.data();

        if (invitationData.status !== 'pending') {
            return res.status(400).json({
                success: false,
                message: 'Solo se pueden reenviar invitaciones pendientes'
            });
        }

        // Reenviar email
        const emailResult = await emailService.sendInvitationEmail(
            invitationData.email,
            invitationData.role,
            req.userName,
            invitationData.customMessage
        );

        if (!emailResult.success) {
            return res.status(500).json({
                success: false,
                message: 'Error reenviando el email',
                error: emailResult.error
            });
        }

        // Actualizar invitación
        await invitationRef.update({
            emailMessageId: emailResult.messageId,
            emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
            resentCount: (invitationData.resentCount || 0) + 1
        });

        res.json({
            success: true,
            message: 'Invitación reenviada correctamente',
            data: {
                messageId: emailResult.messageId
            }
        });

    } catch (error) {
        console.error('Error reenviando invitación:', error);
        res.status(500).json({
            success: false,
            message: 'Error reenviando invitación'
        });
    }
});

module.exports = router;
