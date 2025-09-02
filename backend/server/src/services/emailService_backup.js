const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = null;
        this.initializeTransporter();
    }

    initializeTransporter() {
        // Configuración para Gmail (puedes cambiar por otros proveedores)
        this.transporter = nodemailer.createTransporter({
            service: 'gmail',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS // App password para Gmail
            }
        });

        // Verificar la configuración
        this.transporter.verify((error, success) => {
            if (error) {
                console.error('Error en configuración de email:', error);
            } else {
                console.log('✅ Servidor de email configurado correctamente');
            }
        });
    }

    async sendInvitationEmail(userEmail, userRole, inviterName, customMessage = '') {
        try {
            const subject = `Invitación a ShareDance - ${this.getRoleDisplayName(userRole)}`;
            const htmlContent = this.generateInvitationHTML(userEmail, userRole, inviterName, customMessage);

            const mailOptions = {
                from: {
                    name: 'ShareDance',
                    address: process.env.EMAIL_USER
                },
                to: userEmail,
                subject: subject,
                html: htmlContent
            };

            const info = await this.transporter.sendMail(mailOptions);
            console.log('✅ Email enviado:', info.messageId);

            return {
                success: true,
                messageId: info.messageId,
                message: 'Invitación enviada correctamente'
            };
        } catch (error) {
            console.error('❌ Error enviando email:', error);
            return {
                success: false,
                error: error.message,
                message: 'Error al enviar la invitación'
            };
        }
    }

    getRoleDisplayName(role) {
        const roleNames = {
            'teacher': 'Profesor',
            'admin': 'Administrador',
            'student': 'Estudiante'
        };
        return roleNames[role] || 'Usuario';
    }

    generateInvitationHTML(userEmail, userRole, inviterName, customMessage) {
        const roleDisplayName = this.getRoleDisplayName(userRole);
        const appUrl = process.env.APP_URL || 'https://sharedance.com';

        return `
        <!DOCTYPE html>
        <html lang="es">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Invitación a ShareDance</title>
            <style>
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: #f5f5f5;
                }
                .container {
                    background: white;
                    padding: 40px;
                    border-radius: 12px;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                }
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                }
                .logo {
                    font-size: 28px;
                    font-weight: bold;
                    color: #6366F1;
                    margin-bottom: 10px;
                }
                .title {
                    font-size: 24px;
                    color: #1e293b;
                    margin-bottom: 20px;
                }
                .content {
                    margin-bottom: 30px;
                }
                .role-badge {
                    display: inline-block;
                    padding: 8px 16px;
                    background: linear-gradient(135deg, #6366F1, #8B8FF1);
                    color: white;
                    border-radius: 20px;
                    font-weight: 500;
                    margin: 10px 0;
                }
                .cta-button {
                    display: inline-block;
                    padding: 14px 28px;
                    background: linear-gradient(135deg, #6366F1, #8B8FF1);
                    color: white;
                    text-decoration: none;
                    border-radius: 8px;
                    font-weight: 500;
                    margin: 20px 0;
                }
                .custom-message {
                    background: #f8fafc;
                    padding: 20px;
                    border-left: 4px solid #6366F1;
                    margin: 20px 0;
                    border-radius: 4px;
                }
                .footer {
                    margin-top: 40px;
                    padding-top: 20px;
                    border-top: 1px solid #e2e8f0;
                    font-size: 14px;
                    color: #64748b;
                    text-align: center;
                }
                .features {
                    margin: 30px 0;
                }
                .feature {
                    margin: 10px 0;
                    display: flex;
                    align-items: center;
                }
                .feature-icon {
                    color: #6366F1;
                    margin-right: 10px;
                    font-weight: bold;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="logo">💃 ShareDance</div>
                    <h1 class="title">¡Has sido invitado!</h1>
                </div>
                
                <div class="content">
                    <p>Hola,</p>
                    <p><strong>${inviterName}</strong> te ha invitado a unirte a ShareDance como:</p>
                    <div class="role-badge">${roleDisplayName}</div>
                    
                    ${customMessage ? `
                    <div class="custom-message">
                        <strong>Mensaje personal:</strong><br>
                        ${customMessage}
                    </div>
                    ` : ''}
                    
                    <p>ShareDance es la plataforma líder para la gestión de clases de baile, donde puedes:</p>
                    
                    <div class="features">
                        <div class="feature">
                            <span class="feature-icon">✨</span>
                            <span>Gestionar clases y horarios</span>
                        </div>
                        <div class="feature">
                            <span class="feature-icon">📅</span>
                            <span>Sistema de reservas inteligente</span>
                        </div>
                        <div class="feature">
                            <span class="feature-icon">💳</span>
                            <span>Manejo de créditos y pagos</span>
                        </div>
                        <div class="feature">
                            <span class="feature-icon">📊</span>
                            <span>Reportes y estadísticas detalladas</span>
                        </div>
                    </div>
                    
                    <p>Para comenzar, simplemente descarga la app o accede al dashboard:</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="${appUrl}/register?email=${encodeURIComponent(userEmail)}&role=${userRole}" class="cta-button">
                            Aceptar Invitación
                        </a>
                    </div>
                    
                    <p><strong>Tu email de acceso:</strong> ${userEmail}</p>
                    <p><strong>Rol asignado:</strong> ${roleDisplayName}</p>
                </div>
                
                <div class="footer">
                    <p>Esta invitación fue enviada por ${inviterName} desde ShareDance.</p>
                    <p>Si no esperabas esta invitación, puedes ignorar este email.</p>
                    <p>© 2025 ShareDance. Todos los derechos reservados.</p>
                </div>
            </div>
        </body>
        </html>
        `;
    }

    async sendPasswordResetEmail(userEmail, resetToken) {
        try {
            const subject = 'Restablecer contraseña - ShareDance';
            const resetUrl = `${process.env.APP_URL}/reset-password?token=${resetToken}`;

            const htmlContent = `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>Restablecer Contraseña</title>
                <style>
                    body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
                    .container { background: white; padding: 30px; border-radius: 8px; }
                    .button { display: inline-block; padding: 12px 24px; background: #6366F1; color: white; text-decoration: none; border-radius: 6px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h2>Restablecer tu contraseña</h2>
                    <p>Hola,</p>
                    <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta en ShareDance.</p>
                    <p>Haz clic en el siguiente enlace para crear una nueva contraseña:</p>
                    <p><a href="${resetUrl}" class="button">Restablecer Contraseña</a></p>
                    <p>Si no solicitaste este cambio, puedes ignorar este email.</p>
                    <p>El enlace expirará en 1 hora.</p>
                </div>
            </body>
            </html>
            `;

            const mailOptions = {
                from: {
                    name: 'ShareDance',
                    address: process.env.EMAIL_USER
                },
                to: userEmail,
                subject: subject,
                html: htmlContent
            };

            const info = await this.transporter.sendMail(mailOptions);
            return {
                success: true,
                messageId: info.messageId
            };
        } catch (error) {
            console.error('Error enviando email de reset:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }
}

module.exports = new EmailService();
