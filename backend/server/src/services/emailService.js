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
            this.transporter = nodemailer.createTransport({
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

    async sendWelcomeEmailWithCredentials(userEmail, userName, userRole, temporaryPassword, inviterName, customMessage = '') {
        try {
            // Generar reset password link
            const resetLink = await this.generatePasswordResetLink(userEmail);
            
            // Extraer firstName y lastName del userName
            const nameParts = userName.split(' ');
            const firstName = nameParts[0] || '';
            const lastName = nameParts.slice(1).join(' ') || '';

            const subject = `¡Bienvenido a ShareDance! - Credenciales de acceso`;
            const htmlContent = this.createCredentialsEmailTemplate(
                firstName, 
                lastName, 
                userEmail, 
                temporaryPassword, 
                resetLink, 
                userRole
            );

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
            console.log('✅ Email con credenciales enviado:', info.messageId);
            if (resetLink) {
                console.log('🔗 Reset link generado y incluido en el email');
            }

            return {
                success: true,
                messageId: info.messageId,
                resetLinkGenerated: !!resetLink,
                message: 'Email con credenciales enviado correctamente'
            };

        } catch (error) {
            console.error('❌ Error enviando email con credenciales:', error);
            return {
                success: false,
                error: error.message,
                message: 'Error al enviar las credenciales'
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
            'manager': 'Gerente',
            'Profesor': 'Profesor',
            'Teacher': 'Profesor',
            'Administrador': 'Administrador',
            'Admin': 'Administrador',
            'Estudiante': 'Estudiante',
            'Student': 'Estudiante'
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

    generateCredentialsHTML(userEmail, userName, userRole, temporaryPassword, inviterName, customMessage) {
        const roleDisplayName = this.getRoleDisplayName(userRole);
        const baseUrl = process.env.FRONTEND_URL || 'https://sharedance.com.ar';
        const dashboardUrl = `${baseUrl}/dashboard`;

        return `
        <!DOCTYPE html>
        <html lang="es">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Credenciales ShareDance</title>
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
                .credentials-box {
                    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
                    color: white;
                    padding: 25px;
                    border-radius: 8px;
                    text-align: center;
                    margin: 25px 0;
                }
                .credential-item {
                    background-color: rgba(255,255,255,0.2);
                    padding: 12px 20px;
                    border-radius: 6px;
                    margin: 10px 0;
                    font-family: monospace;
                    font-size: 16px;
                    word-break: break-all;
                }
                .warning-box {
                    background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
                    color: white;
                    padding: 20px;
                    border-radius: 8px;
                    margin: 20px 0;
                    text-align: center;
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
                    <div>Plataforma de gestión de clases de baile</div>
                </div>

                <div>
                    <h2>¡Bienvenido/a a ShareDance, ${userName}!</h2>
                    
                    <p><strong>${inviterName}</strong> te ha creado una cuenta como <strong>${roleDisplayName}</strong>.</p>

                    <div class="credentials-box">
                        <h3>🔐 Tus credenciales de acceso</h3>
                        <div style="margin: 20px 0;">
                            <p><strong>Email:</strong></p>
                            <div class="credential-item">${userEmail}</div>
                        </div>
                        <div style="margin: 20px 0;">
                            <p><strong>Contraseña temporal:</strong></p>
                            <div class="credential-item">${temporaryPassword}</div>
                        </div>
                    </div>

                    <div class="warning-box">
                        <h4>⚠️ IMPORTANTE: Cambio de contraseña requerido</h4>
                        <p>Por seguridad, deberás cambiar tu contraseña en el primer inicio de sesión.</p>
                    </div>

                    ${customMessage ? `
                    <div style="background-color: #f8fafc; border-left: 4px solid #6366f1; padding: 20px; margin: 20px 0;">
                        <h4>📝 Mensaje personal:</h4>
                        <p>${customMessage}</p>
                    </div>
                    ` : ''}

                    <div style="text-align: center;">
                        <a href="${dashboardUrl}" class="cta-button">
                            🚀 Acceder al Dashboard
                        </a>
                    </div>

                    <h3>🎭 Funciones de ShareDance:</h3>
                    <ul>
                        <li><strong>Gestionar clases</strong> - Crea y administra clases de baile</li>
                        <li><strong>Sistema de créditos</strong> - Maneja créditos y reservas</li>
                        <li><strong>Reservas en tiempo real</strong> - Sistema de reservas inteligente</li>
                        <li><strong>Comunicación directa</strong> - Chat con estudiantes e instructores</li>
                    </ul>

                    <p><strong>Pasos para empezar:</strong></p>
                    <ol>
                        <li>Haz clic en "Acceder al Dashboard"</li>
                        <li>Inicia sesión con las credenciales de arriba</li>
                        <li>Cambia tu contraseña por una nueva y segura</li>
                        <li>Completa tu perfil y ¡empieza a usar ShareDance!</li>
                    </ol>
                </div>

                <div class="footer">
                    <p>ShareDance - Plataforma de gestión de clases de baile<br>
                    <a href="https://sharedance.com.ar">sharedance.com.ar</a></p>
                    
                    <p style="font-size: 12px; color: #999;">
                        Por favor, no compartas estas credenciales con nadie.<br>
                        Si no solicitaste esta cuenta, ignora este email.
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

    /**
     * Generar link de reset de contraseña de Firebase
     */
    async generatePasswordResetLink(email) {
        try {
            const admin = require('firebase-admin');
            const actionCodeSettings = {
                url: 'https://sharedance.com.ar/dashboard/login?mode=reset-complete',
                handleCodeInApp: false
            };
            
            const resetLink = await admin.auth().generatePasswordResetLink(email, actionCodeSettings);
            return resetLink;
        } catch (error) {
            console.error('Error generando reset link:', error);
            return null;
        }
    }

    /**
     * Crear template de email con credenciales y reset link
     */
    createCredentialsEmailTemplate(firstName, lastName, email, temporaryPassword, resetLink, role = 'instructor') {
        const userName = `${firstName} ${lastName}`;
        const roleDisplayName = role === 'instructor' ? 'Instructor' : 
                               role === 'admin' ? 'Administrador' : 'Usuario';
        const dashboardUrl = 'https://sharedance.com.ar/dashboard/';

        return `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Bienvenido a ShareDance</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
                    line-height: 1.6;
                    margin: 0;
                    padding: 0;
                    background-color: #f5f5f5;
                }
                .container {
                    max-width: 600px;
                    margin: 20px auto;
                    background: white;
                    border-radius: 12px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                    overflow: hidden;
                }
                .header {
                    background: linear-gradient(135deg, #6366F1, #8B5CF6);
                    color: white;
                    padding: 30px;
                    text-align: center;
                }
                .logo {
                    font-size: 28px;
                    font-weight: bold;
                    margin-bottom: 10px;
                }
                .content {
                    padding: 30px;
                }
                .welcome-banner {
                    background: #f8fafc;
                    border-left: 4px solid #6366F1;
                    padding: 20px;
                    margin-bottom: 30px;
                    border-radius: 8px;
                }
                .credentials-box {
                    background: #fef3c7;
                    border: 2px solid #f59e0b;
                    border-radius: 8px;
                    padding: 20px;
                    margin: 20px 0;
                }
                .reset-box {
                    background: #e0f2fe;
                    border: 2px solid #0891b2;
                    border-radius: 8px;
                    padding: 20px;
                    margin: 20px 0;
                    text-align: center;
                }
                .cta-button {
                    display: inline-block;
                    background: #6366F1;
                    color: white !important;
                    padding: 12px 24px;
                    text-decoration: none;
                    border-radius: 6px;
                    font-weight: 600;
                    margin: 10px 5px;
                }
                .reset-button {
                    display: inline-block;
                    background: #0891b2;
                    color: white !important;
                    padding: 12px 24px;
                    text-decoration: none;
                    border-radius: 6px;
                    font-weight: 600;
                    margin: 10px 5px;
                }
                .security-warning {
                    background: #fef2f2;
                    border-left: 4px solid #ef4444;
                    padding: 15px;
                    margin: 20px 0;
                    border-radius: 4px;
                }
                .footer {
                    background: #f8fafc;
                    padding: 20px;
                    text-align: center;
                    color: #6b7280;
                    font-size: 14px;
                }
                h1 { color: #1f2937; margin: 0 0 10px 0; }
                h2 { color: #374151; margin: 20px 0 10px 0; }
                h3 { color: #4b5563; margin: 15px 0 10px 0; }
                p { margin: 8px 0; }
                .credential-item {
                    background: white;
                    padding: 8px 12px;
                    margin: 5px 0;
                    border-radius: 4px;
                    border: 1px solid #e5e7eb;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="logo">💃 ShareDance</div>
                    <p style="margin: 0; opacity: 0.9;">Plataforma de gestión de clases de baile</p>
                </div>

                <div class="content">
                    <div class="welcome-banner">
                        <h1>¡Bienvenido/a, ${userName}!</h1>
                        <p>Tu cuenta como <strong>${roleDisplayName}</strong> ha sido creada exitosamente.</p>
                    </div>

                    <h2>🔑 Opciones para acceder a tu cuenta:</h2>

                    <div class="credentials-box">
                        <h3>Opción 1: Credenciales temporales</h3>
                        <p>Puedes usar estas credenciales para tu primer acceso:</p>
                        <div class="credential-item">
                            <strong>📧 Email:</strong> ${email}
                        </div>
                        <div class="credential-item">
                            <strong>🔒 Contraseña temporal:</strong> <code style="background: #f3f4f6; padding: 2px 6px; border-radius: 3px; font-family: monospace;">${temporaryPassword}</code>
                        </div>
                    </div>

                    ${resetLink ? `
                    <div class="reset-box">
                        <h3>Opción 2: Cambiar contraseña directamente</h3>
                        <p>Si prefieres establecer tu propia contraseña desde el inicio:</p>
                        <a href="${resetLink}" class="reset-button">
                            🔧 Cambiar Contraseña
                        </a>
                        <p style="font-size: 14px; color: #6b7280; margin-top: 15px;">
                            Este link te permitirá establecer una contraseña personalizada
                        </p>
                    </div>
                    ` : ''}

                    <div class="security-warning">
                        <h3>⚠️ Importante - Seguridad</h3>
                        <p><strong>Por tu seguridad, debes cambiar la contraseña temporal en tu primer acceso.</strong></p>
                        <p>Una vez que ingreses al dashboard, dirígete a tu perfil para actualizar tu contraseña.</p>
                    </div>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="${dashboardUrl}" class="cta-button">
                            🚀 Ir al Dashboard
                        </a>
                    </div>

                    <div style="border-top: 1px solid #e5e7eb; padding-top: 20px; margin-top: 30px;">
                        <h3>📱 ¿Qué puedes hacer como ${roleDisplayName}?</h3>
                        ${role === 'instructor' ? `
                        <ul style="color: #4b5563;">
                            <li>📅 Gestionar tus clases asignadas</li>
                            <li>👥 Ver lista de estudiantes inscritos</li>
                            <li>✅ Marcar asistencia de clases</li>
                            <li>📊 Ver reportes de tus clases</li>
                            <li>⚙️ Configurar tu perfil y disponibilidad</li>
                        </ul>
                        ` : `
                        <ul style="color: #4b5563;">
                            <li>🏢 Gestión completa del estudio</li>
                            <li>👨‍🏫 Administrar instructores</li>
                            <li>👥 Gestionar estudiantes</li>
                            <li>📊 Ver reportes y analytics</li>
                            <li>⚙️ Configuración del sistema</li>
                        </ul>
                        `}
                    </div>
                </div>

                <div class="footer">
                    <p>Si tienes alguna pregunta, no dudes en contactarnos.<br>
                    <a href="https://sharedance.com.ar" style="color: #6366F1;">sharedance.com.ar</a></p>
                </div>
            </div>
        </body>
        </html>
        `;
    }
}

module.exports = EmailService;
