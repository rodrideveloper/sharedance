const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = null;
        this.initializeTransporter();
    }

    initializeTransporter() {
        this.transporter = nodemailer.createTransport({
            service: process.env.EMAIL_SERVICE || 'gmail',
            host: process.env.EMAIL_HOST || 'smtp.gmail.com',
            port: parseInt(process.env.EMAIL_PORT) || 587,
            secure: process.env.EMAIL_SECURE === 'true',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS,
            },
        });
    }

    async sendInvitationEmail(to, role, inviterName, customMessage = '') {
        try {
            const html = this.generateInvitationHTML(role, inviterName, customMessage);

            const mailOptions = {
                from: {
                    name: 'ShareDance',
                    address: process.env.EMAIL_USER
                },
                to: to,
                subject: `Invitación para unirte a ShareDance como ${role}`,
                html: html,
            };

            const result = await this.transporter.sendMail(mailOptions);
            console.log('Email enviado:', result.messageId);
            return { success: true, messageId: result.messageId };
        } catch (error) {
            console.error('Error enviando email:', error);
            return { success: false, error: error.message };
        }
    }

    generateInvitationHTML(role, inviterName, customMessage) {
        const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3001';

        return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Invitación a ShareDance</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
            }
            .header {
                background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%);
                color: white;
                padding: 30px;
                text-align: center;
                border-radius: 12px 12px 0 0;
            }
            .header h1 {
                margin: 0;
                font-size: 28px;
                font-weight: 700;
            }
            .content {
                background: white;
                padding: 30px;
                border-left: 1px solid #e5e7eb;
                border-right: 1px solid #e5e7eb;
            }
            .role-badge {
                display: inline-block;
                background: #f3f4f6;
                color: #374151;
                padding: 8px 16px;
                border-radius: 20px;
                font-weight: 600;
                font-size: 14px;
                margin: 10px 0;
            }
            .cta-button {
                display: inline-block;
                background: #6366F1;
                color: white;
                padding: 16px 32px;
                text-decoration: none;
                border-radius: 8px;
                font-weight: 600;
                margin: 20px 0;
                text-align: center;
            }
            .footer {
                background: #f9fafb;
                padding: 20px 30px;
                text-align: center;
                color: #6b7280;
                font-size: 14px;
                border-radius: 0 0 12px 12px;
                border: 1px solid #e5e7eb;
                border-top: none;
            }
            .custom-message {
                background: #f0f9ff;
                border-left: 4px solid #3b82f6;
                padding: 16px;
                margin: 20px 0;
                border-radius: 0 8px 8px 0;
            }
            .container {
                background: white;
                border-radius: 12px;
                overflow: hidden;
                box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🕺 ShareDance</h1>
                <p style="margin: 10px 0 0 0; opacity: 0.9;">Tu plataforma de danza favorita</p>
            </div>
            
            <div class="content">
                <h2>¡Hola! 👋</h2>
                <p><strong>${inviterName}</strong> te ha invitado a unirte a ShareDance como:</p>
                
                <div class="role-badge">
                    ${this.getRoleIcon(role)} ${role}
                </div>
                
                <p>ShareDance es una plataforma innovadora donde puedes:</p>
                <ul>
                    <li>🎵 Aprender nuevos estilos de baile</li>
                    <li>📅 Reservar clases con los mejores instructores</li>
                    <li>👥 Conectar con una comunidad apasionada por la danza</li>
                    <li>📈 Seguir tu progreso y evolución</li>
                </ul>
                
                ${customMessage ? `
                <div class="custom-message">
                    <h4>Mensaje personal de ${inviterName}:</h4>
                    <p>"${customMessage}"</p>
                </div>
                ` : ''}
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${baseUrl}/register?invitation=true&role=${role}" class="cta-button">
                        Aceptar Invitación
                    </a>
                </div>
                
                <p style="color: #6b7280; font-size: 14px;">
                    Si no puedes hacer clic en el botón, copia y pega este enlace en tu navegador:<br>
                    <a href="${baseUrl}/register?invitation=true&role=${role}" style="color: #6366F1;">
                        ${baseUrl}/register?invitation=true&role=${role}
                    </a>
                </p>
            </div>
            
            <div class="footer">
                <p><strong>ShareDance Team</strong></p>
                <p>Si tienes alguna pregunta, no dudes en contactarnos.</p>
                <p style="margin-top: 15px; font-size: 12px;">
                    Este correo fue enviado a tu dirección porque fuiste invitado a ShareDance.
                </p>
            </div>
        </div>
    </body>
    </html>
    `;
    }

    getRoleIcon(role) {
        const icons = {
            'Profesor': '👨‍🏫',
            'Teacher': '👨‍🏫',
            'Administrador': '⚡',
            'Admin': '⚡',
            'Estudiante': '🎓',
            'Student': '🎓'
        };
        return icons[role] || '👤';
    }

    async sendPasswordResetEmail(to, resetToken) {
        try {
            const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3001';
            const resetUrl = `${baseUrl}/reset-password?token=${resetToken}`;

            const html = `
      <!DOCTYPE html>
      <html lang="es">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Recuperar Contraseña - ShareDance</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  line-height: 1.6;
                  color: #333;
                  max-width: 600px;
                  margin: 0 auto;
                  padding: 20px;
              }
              .container {
                  background: white;
                  border-radius: 12px;
                  overflow: hidden;
                  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
              }
              .header {
                  background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%);
                  color: white;
                  padding: 30px;
                  text-align: center;
              }
              .content {
                  padding: 30px;
              }
              .cta-button {
                  display: inline-block;
                  background: #6366F1;
                  color: white;
                  padding: 16px 32px;
                  text-decoration: none;
                  border-radius: 8px;
                  font-weight: 600;
                  margin: 20px 0;
              }
              .footer {
                  background: #f9fafb;
                  padding: 20px;
                  text-align: center;
                  color: #6b7280;
                  font-size: 14px;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="header">
                  <h1>🔐 Recuperar Contraseña</h1>
              </div>
              <div class="content">
                  <h2>Solicitud de Cambio de Contraseña</h2>
                  <p>Hemos recibido una solicitud para restablecer tu contraseña en ShareDance.</p>
                  <p>Haz clic en el siguiente botón para crear una nueva contraseña:</p>
                  
                  <div style="text-align: center;">
                      <a href="${resetUrl}" class="cta-button">Restablecer Contraseña</a>
                  </div>
                  
                  <p style="color: #6b7280; font-size: 14px;">
                      Este enlace expirará en 1 hora por seguridad.<br>
                      Si no solicitaste este cambio, puedes ignorar este correo.
                  </p>
              </div>
              <div class="footer">
                  <p>ShareDance Team</p>
              </div>
          </div>
      </body>
      </html>
      `;

            const mailOptions = {
                from: {
                    name: 'ShareDance',
                    address: process.env.EMAIL_USER
                },
                to: to,
                subject: 'Recuperar Contraseña - ShareDance',
                html: html,
            };

            const result = await this.transporter.sendMail(mailOptions);
            return { success: true, messageId: result.messageId };
        } catch (error) {
            console.error('Error enviando email de recuperación:', error);
            return { success: false, error: error.message };
        }
    }

    async testConnection() {
        try {
            await this.transporter.verify();
            console.log('Conexión de email configurada correctamente');
            return true;
        } catch (error) {
            console.error('Error en la configuración de email:', error);
            return false;
        }
    }
}

module.exports = EmailService;
