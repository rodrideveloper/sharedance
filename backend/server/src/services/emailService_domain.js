const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = null;
        this.initializeTransporter();
    }

    initializeTransporter() {
        // Detect environment and configure accordingly
        const isDevelopment = process.env.NODE_ENV === 'development';
        const useGmail = process.env.USE_GMAIL === 'true';

        if (isDevelopment && useGmail) {
            // Development with Gmail
            console.log('🔧 Configurando Gmail para desarrollo...');
            this.transporter = nodemailer.createTransporter({
                service: 'gmail',
                auth: {
                    user: process.env.EMAIL_USER,
                    pass: process.env.EMAIL_PASS
                }
            });
        } else {
            // Production with local Postfix server
            console.log('🚀 Configurando servidor de correo local...');
            this.transporter = nodemailer.createTransporter({
                host: 'localhost',
                port: 25,
                secure: false, // Use TLS
                tls: {
                    rejectUnauthorized: false
                },
                auth: false // No authentication needed for local server
            });
        }

        // Verify configuration
        this.transporter.verify((error, success) => {
            if (error) {
                console.error('❌ Error en configuración de email:', error);
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
                    address: this.getFromEmail()
                },
                to: userEmail,
                subject: subject,
                html: htmlContent,
                replyTo: 'noreply@sharedance.com.ar'
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

    getFromEmail() {
        const isDevelopment = process.env.NODE_ENV === 'development';
        const useGmail = process.env.USE_GMAIL === 'true';

        if (isDevelopment && useGmail) {
            return process.env.EMAIL_USER;
        } else {
            return 'noreply@sharedance.com.ar';
        }
    }

    getRoleDisplayName(role) {
        const roleNames = {
            'admin': 'Administrador',
            'instructor': 'Instructor',
            'student': 'Estudiante',
            'manager': 'Gerente'
        };
        return roleNames[role] || 'Usuario';
    }

    generateInvitationHTML(userEmail, userRole, inviterName, customMessage) {
        const roleDisplayName = this.getRoleDisplayName(userRole);
        const baseUrl = process.env.FRONTEND_URL || 'https://sharedance.com.ar';
        const dashboardUrl = `${baseUrl}/dashboard`;
        
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
                    background-color: white;
                    border-radius: 12px;
                    padding: 40px;
                    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                }
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                    padding-bottom: 20px;
                    border-bottom: 2px solid #e0e0e0;
                }
                .logo {
                    font-size: 28px;
                    font-weight: bold;
                    color: #6366f1;
                    margin-bottom: 10px;
                }
                .subtitle {
                    color: #666;
                    font-size: 16px;
                }
                .content {
                    margin: 30px 0;
                }
                .invitation-box {
                    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
                    color: white;
                    padding: 25px;
                    border-radius: 8px;
                    text-align: center;
                    margin: 25px 0;
                }
                .role-badge {
                    background-color: rgba(255,255,255,0.2);
                    padding: 8px 16px;
                    border-radius: 20px;
                    display: inline-block;
                    margin: 10px 0;
                    font-weight: bold;
                }
                .cta-button {
                    display: inline-block;
                    background-color: #10b981;
                    color: white;
                    padding: 15px 30px;
                    text-decoration: none;
                    border-radius: 6px;
                    font-weight: bold;
                    margin: 20px 0;
                    transition: background-color 0.3s;
                }
                .cta-button:hover {
                    background-color: #059669;
                }
                .custom-message {
                    background-color: #f8fafc;
                    border-left: 4px solid #6366f1;
                    padding: 20px;
                    margin: 20px 0;
                    border-radius: 0 8px 8px 0;
                }
                .footer {
                    text-align: center;
                    margin-top: 40px;
                    padding-top: 20px;
                    border-top: 1px solid #e0e0e0;
                    color: #666;
                    font-size: 14px;
                }
                .social-links {
                    margin: 15px 0;
                }
                .social-links a {
                    color: #6366f1;
                    text-decoration: none;
                    margin: 0 10px;
                }
                @media (max-width: 600px) {
                    body {
                        padding: 10px;
                    }
                    .container {
                        padding: 20px;
                    }
                    .logo {
                        font-size: 24px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="logo">💃 ShareDance</div>
                    <div class="subtitle">Plataforma de gestión de clases de baile</div>
                </div>

                <div class="content">
                    <h2>¡Has sido invitado/a a unirte a ShareDance!</h2>
                    
                    <p>Hola,</p>
                    
                    <p><strong>${inviterName}</strong> te ha invitado a formar parte de la plataforma ShareDance.</p>

                    <div class="invitation-box">
                        <h3>🎯 Tu invitación</h3>
                        <p>Has sido invitado/a como:</p>
                        <div class="role-badge">${roleDisplayName}</div>
                        <p>Email: <strong>${userEmail}</strong></p>
                    </div>

                    ${customMessage ? `
                    <div class="custom-message">
                        <h4>📝 Mensaje personal:</h4>
                        <p>${customMessage}</p>
                    </div>
                    ` : ''}

                    <div style="text-align: center;">
                        <a href="${dashboardUrl}" class="cta-button">
                            🚀 Acceder al Dashboard
                        </a>
                    </div>

                    <h3>🎭 ¿Qué puedes hacer en ShareDance?</h3>
                    <ul>
                        <li><strong>Gestionar clases</strong> - Crea y administra clases de baile</li>
                        <li><strong>Sistema de créditos</strong> - Maneja créditos y reservas</li>
                        <li><strong>Reservas en tiempo real</strong> - Sistema de reservas inteligente</li>
                        <li><strong>Comunicación directa</strong> - Chat con estudiantes e instructores</li>
                        <li><strong>Reportes detallados</strong> - Analiza el rendimiento de tu estudio</li>
                    </ul>

                    <p>Si tienes alguna pregunta, no dudes en contactarnos. ¡Esperamos verte pronto en la pista! 💃🕺</p>
                </div>

                <div class="footer">
                    <p>Este email fue enviado por ShareDance<br>
                    <a href="https://sharedance.com.ar">sharedance.com.ar</a></p>
                    
                    <div class="social-links">
                        <a href="#">Instagram</a> |
                        <a href="#">Facebook</a> |
                        <a href="#">YouTube</a>
                    </div>
                    
                    <p style="font-size: 12px; color: #999;">
                        Si no esperabas este email, puedes ignorarlo de forma segura.
                    </p>
                </div>
            </div>
        </body>
        </html>
        `;
    }

    async sendWelcomeEmail(userEmail, userName, userRole) {
        try {
            const subject = `¡Bienvenido/a a ShareDance, ${userName}!`;
            const htmlContent = this.generateWelcomeHTML(userName, userRole);

            const mailOptions = {
                from: {
                    name: 'ShareDance',
                    address: this.getFromEmail()
                },
                to: userEmail,
                subject: subject,
                html: htmlContent,
                replyTo: 'noreply@sharedance.com.ar'
            };

            const info = await this.transporter.sendMail(mailOptions);
            console.log('✅ Email de bienvenida enviado:', info.messageId);

            return {
                success: true,
                messageId: info.messageId,
                message: 'Email de bienvenida enviado correctamente'
            };

        } catch (error) {
            console.error('❌ Error enviando email de bienvenida:', error);
            return {
                success: false,
                error: error.message,
                message: 'Error al enviar email de bienvenida'
            };
        }
    }

    generateWelcomeHTML(userName, userRole) {
        const roleDisplayName = this.getRoleDisplayName(userRole);
        const baseUrl = process.env.FRONTEND_URL || 'https://sharedance.com.ar';
        const dashboardUrl = `${baseUrl}/dashboard`;
        
        return `
        <!DOCTYPE html>
        <html lang="es">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Bienvenido/a a ShareDance</title>
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
                    background-color: white;
                    border-radius: 12px;
                    padding: 40px;
                    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                }
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                }
                .logo {
                    font-size: 32px;
                    font-weight: bold;
                    color: #6366f1;
                    margin-bottom: 10px;
                }
                .welcome-banner {
                    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
                    color: white;
                    padding: 30px;
                    border-radius: 8px;
                    text-align: center;
                    margin: 25px 0;
                }
                .cta-button {
                    display: inline-block;
                    background-color: #6366f1;
                    color: white;
                    padding: 15px 30px;
                    text-decoration: none;
                    border-radius: 6px;
                    font-weight: bold;
                    margin: 20px 0;
                }
                .footer {
                    text-align: center;
                    margin-top: 40px;
                    padding-top: 20px;
                    border-top: 1px solid #e0e0e0;
                    color: #666;
                    font-size: 14px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="logo">💃 ShareDance</div>
                </div>

                <div class="welcome-banner">
                    <h1>¡Bienvenido/a, ${userName}!</h1>
                    <p>Tu cuenta como <strong>${roleDisplayName}</strong> está lista</p>
                </div>

                <div style="text-align: center;">
                    <a href="${dashboardUrl}" class="cta-button">
                        🚀 Ir al Dashboard
                    </a>
                </div>

                <div class="footer">
                    <p>ShareDance - Plataforma de gestión de clases de baile<br>
                    <a href="https://sharedance.com.ar">sharedance.com.ar</a></p>
                </div>
            </div>
        </body>
        </html>
        `;
    }
}

module.exports = EmailService;
