const express = require('express');
const admin = require('firebase-admin');
const Joi = require('joi');
const EmailService = require('../services/emailService');
const crypto = require('crypto');

const router = express.Router();
const emailService = new EmailService();

// Validaciones con Joi
const invitationSchema = Joi.object({
    email: Joi.string().email().required(),
    role: Joi.string().valid('Profesor', 'Teacher', 'Administrador', 'Admin', 'Estudiante', 'Student').required(),
    customMessage: Joi.string().optional().allow(''),
    inviterName: Joi.string().optional().default('ShareDance Team'),
    createUser: Joi.boolean().optional().default(false),
    sendCredentials: Joi.boolean().optional().default(false)
});

// Función para generar contraseña temporal segura
function generateTemporaryPassword() {
    const adjectives = ['Agil', 'Suave', 'Ritmo', 'Baile', 'Gracia', 'Flow', 'Salsa', 'Tango'];
    const numbers = Math.floor(Math.random() * 999) + 100;
    const adjective = adjectives[Math.floor(Math.random() * adjectives.length)];
    const year = new Date().getFullYear();

    return `SD${year}-${adjective}${numbers}`;
}

// Función para mapear roles en español a inglés
function mapRoleToEnglish(spanishRole) {
    const roleMap = {
        'Profesor': 'instructor',
        'Teacher': 'instructor',
        'Administrador': 'admin',
        'Admin': 'admin',
        'Estudiante': 'student',
        'Student': 'student'
    };
    return roleMap[spanishRole] || 'student';
}

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

// Crear usuario en Firebase Auth
async function createFirebaseUser(email, temporaryPassword, role) {
    try {
        const userRecord = await admin.auth().createUser({
            email: email,
            password: temporaryPassword,
            emailVerified: true,
            disabled: false
        });

        // Crear documento de usuario en Firestore
        const db = admin.firestore();
        const englishRole = mapRoleToEnglish(role);

        await db.collection('users').doc(userRecord.uid).set({
            email: email.toLowerCase(),
            role: englishRole,
            displayName: email.split('@')[0],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            mustChangePassword: true,
            isActive: true,
            profile: {
                firstName: '',
                lastName: '',
                phone: '',
                dateOfBirth: null,
                preferredLanguage: 'es'
            },
            preferences: {
                notifications: {
                    email: true,
                    push: true,
                    sms: false
                },
                privacy: {
                    profileVisible: true,
                    allowMessages: true
                }
            },
            stats: {
                classesAttended: 0,
                totalHours: 0,
                favoriteStyles: []
            }
        });

        // Asignar claims personalizados para el rol
        await admin.auth().setCustomUserClaims(userRecord.uid, {
            role: englishRole,
            mustChangePassword: true
        });

        return {
            success: true,
            uid: userRecord.uid,
            message: 'Usuario creado correctamente'
        };

    } catch (error) {
        console.error('Error creando usuario:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

// Enviar invitación (endpoint existente mejorado)
router.post('/send', authMiddleware, async (req, res) => {
    try {
        const { error, value } = invitationSchema.validate(req.body);

        if (error) {
            return res.status(400).json({
                error: 'Datos de invitación inválidos',
                details: error.details
            });
        }

        const { email, role, customMessage, inviterName, createUser, sendCredentials } = value;
        let temporaryPassword = null;
        let userCreated = false;

        // Verificar si el usuario ya existe
        try {
            const existingUser = await admin.auth().getUserByEmail(email);

            if (createUser) {
                return res.status(400).json({
                    error: 'El usuario ya está registrado en el sistema'
                });
            }
        } catch (authError) {
            // Si no encuentra el usuario y queremos crearlo
            if (authError.code === 'auth/user-not-found' && createUser) {
                temporaryPassword = generateTemporaryPassword();

                const userResult = await createFirebaseUser(email, temporaryPassword, role);

                if (!userResult.success) {
                    return res.status(500).json({
                        error: 'Error creando el usuario',
                        details: userResult.error
                    });
                }

                userCreated = true;
            } else if (authError.code !== 'auth/user-not-found') {
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
            status: userCreated ? 'user_created' : 'pending',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 días
            userCreated: userCreated,
            credentialsSent: sendCredentials && temporaryPassword !== null
        };

        const invitationRef = await db.collection('invitations').add(invitationData);

        // Enviar email apropiado
        let emailResult;

        if (userCreated && sendCredentials && temporaryPassword) {
            // Enviar email con credenciales
            emailResult = await emailService.sendWelcomeEmailWithCredentials(
                email,
                email.split('@')[0], // nombre temporal
                role,
                temporaryPassword,
                inviterName || req.user.name || 'ShareDance Team',
                customMessage
            );
        } else {
            // Enviar invitación normal
            emailResult = await emailService.sendInvitationEmail(
                email,
                role,
                inviterName || req.user.name || 'ShareDance Team',
                customMessage
            );
        }

        if (!emailResult.success) {
            // Si falla el email y creamos usuario, podríamos considerar eliminar el usuario
            // Pero mejor conservar el usuario y marcar la invitación como failed
            await invitationRef.update({
                status: 'email_failed',
                emailError: emailResult.error
            });

            return res.status(500).json({
                error: 'Usuario creado pero error enviando email',
                details: emailResult.error,
                userCreated: userCreated
            });
        }

        // Actualizar con messageId del email
        await invitationRef.update({
            emailMessageId: emailResult.messageId
        });

        const response = {
            message: userCreated
                ? 'Usuario creado y invitación enviada correctamente'
                : 'Invitación enviada correctamente',
            invitationId: invitationRef.id,
            messageId: emailResult.messageId,
            userCreated: userCreated
        };

        // No incluir la contraseña en la respuesta por seguridad
        res.status(201).json(response);

    } catch (error) {
        console.error('Error enviando invitación:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Nuevo endpoint específico para crear profesores
router.post('/create-instructor', authMiddleware, async (req, res) => {
    try {
        const schema = Joi.object({
            email: Joi.string().email().required(),
            customMessage: Joi.string().optional().allow(''),
            inviterName: Joi.string().optional().default('ShareDance Team')
        });

        const { error, value } = schema.validate(req.body);

        if (error) {
            return res.status(400).json({
                error: 'Datos inválidos',
                details: error.details
            });
        }

        const { email, customMessage, inviterName } = value;

        // Verificar que no existe el usuario
        try {
            await admin.auth().getUserByEmail(email);
            return res.status(400).json({
                error: 'El instructor ya está registrado en el sistema'
            });
        } catch (authError) {
            if (authError.code !== 'auth/user-not-found') {
                throw authError;
            }
        }

        // Crear usuario con rol de profesor
        const temporaryPassword = generateTemporaryPassword();
        const userResult = await createFirebaseUser(email, temporaryPassword, 'Profesor');

        if (!userResult.success) {
            return res.status(500).json({
                error: 'Error creando el instructor',
                details: userResult.error
            });
        }

        // Crear invitación
        const db = admin.firestore();
        const invitationData = {
            email: email.toLowerCase(),
            role: 'Profesor',
            customMessage: customMessage || 'Bienvenido al equipo de instructores de ShareDance',
            inviterName: inviterName || req.user.name || 'ShareDance Team',
            inviterId: req.user.uid,
            status: 'instructor_created',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 días para instructores
            userCreated: true,
            credentialsSent: true
        };

        const invitationRef = await db.collection('invitations').add(invitationData);

        // Enviar email con credenciales
        const emailResult = await emailService.sendWelcomeEmailWithCredentials(
            email,
            email.split('@')[0],
            'Profesor',
            temporaryPassword,
            inviterName || req.user.name || 'ShareDance Team',
            customMessage || 'Bienvenido al equipo de instructores de ShareDance'
        );

        if (!emailResult.success) {
            await invitationRef.update({
                status: 'email_failed',
                emailError: emailResult.error
            });
        } else {
            await invitationRef.update({
                emailMessageId: emailResult.messageId
            });
        }

        res.status(201).json({
            message: 'Instructor creado correctamente',
            instructorId: userResult.uid,
            invitationId: invitationRef.id,
            emailSent: emailResult.success
        });

    } catch (error) {
        console.error('Error creando instructor:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Obtener todas las invitaciones (endpoint existente)
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
            invitations.push({
                id: doc.id,
                ...doc.data(),
                sentAt: doc.data().sentAt?.toDate(),
                expiresAt: doc.data().expiresAt?.toDate()
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
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Eliminar invitación
router.delete('/:id', authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const db = admin.firestore();

        const invitationRef = db.collection('invitations').doc(id);
        const doc = await invitationRef.get();

        if (!doc.exists) {
            return res.status(404).json({
                error: 'Invitación no encontrada'
            });
        }

        await invitationRef.delete();

        res.json({
            message: 'Invitación eliminada correctamente'
        });

    } catch (error) {
        console.error('Error eliminando invitación:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Reenviar invitación
router.post('/:id/resend', authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const db = admin.firestore();

        const invitationRef = db.collection('invitations').doc(id);
        const doc = await invitationRef.get();

        if (!doc.exists) {
            return res.status(404).json({
                error: 'Invitación no encontrada'
            });
        }

        const invitationData = doc.data();

        // Reenviar email
        const emailResult = await emailService.sendInvitationEmail(
            invitationData.email,
            invitationData.role,
            invitationData.inviterName,
            invitationData.customMessage
        );

        if (!emailResult.success) {
            return res.status(500).json({
                error: 'Error reenviando email',
                details: emailResult.error
            });
        }

        // Actualizar invitación
        await invitationRef.update({
            status: 'resent',
            resentAt: admin.firestore.FieldValue.serverTimestamp(),
            emailMessageId: emailResult.messageId
        });

        res.json({
            message: 'Invitación reenviada correctamente',
            messageId: emailResult.messageId
        });

    } catch (error) {
        console.error('Error reenviando invitación:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

module.exports = router;
