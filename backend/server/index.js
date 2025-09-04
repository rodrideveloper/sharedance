const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const path = require('path');
const admin = require('firebase-admin');
require('dotenv').config();

// Configuration
const getConfig = () => {
    const nodeEnv = process.env.NODE_ENV || 'staging';

    const baseConfig = {
        port: parseInt(process.env.PORT || '3000'),
        nodeEnv,
    };

    switch (nodeEnv) {
        case 'production':
            return {
                ...baseConfig,
                firebase: {
                    projectId: process.env.FIREBASE_PROJECT_ID || 'sharedance-production',
                    serviceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './serviceAccount-production.json',
                    databaseURL: process.env.FIREBASE_DATABASE_URL,
                },
                cors: {
                    origin: [
                        'https://sharedance.com.ar',
                        'https://www.sharedance.com.ar',
                        'https://admin.sharedance.com.ar',
                        'https://sharedance-production.web.app',
                    ],
                },
            };

        case 'staging':
        default:
            return {
                ...baseConfig,
                firebase: {
                    projectId: process.env.FIREBASE_PROJECT_ID || 'sharedance-staging',
                    serviceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './serviceAccount-staging.json',
                    databaseURL: process.env.FIREBASE_DATABASE_URL,
                },
                cors: {
                    origin: [
                        'http://localhost:3000',
                        'http://localhost:8080',
                        'https://staging.sharedance.com.ar',
                        'https://staging-admin.sharedance.com.ar',
                        'https://sharedance-staging.web.app',
                    ],
                },
            };
    }
};

const fs = require('fs');

// Get configuration
const config = getConfig();

// Initialize Firebase Admin FIRST
try {
    const serviceAccount = require(config.firebase.serviceAccountPath);

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: config.firebase.projectId,
        databaseURL: config.firebase.databaseURL
    });

    console.log(`🔥 Firebase initialized for ${config.nodeEnv} environment`);
    console.log(`📂 Project: ${config.firebase.projectId}`);
} catch (error) {
    console.error('❌ Failed to initialize Firebase:', error);
    console.error('💡 Make sure you have the correct service account file:', config.firebase.serviceAccountPath);
    process.exit(1);
}

// Initialize Express app
const app = express();
const PORT = config.port;

// Middlewares
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'"]
        }
    }
}));
app.use(compression());
app.use(cors({
    origin: config.cors.origin,
    credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files from public directory (except index.html)
app.use(express.static(path.join(__dirname, 'public'), { index: false }));

// Serve dynamic index.html with environment variables injected
app.get('/', (req, res) => {
    const indexPath = path.join(__dirname, 'public', 'index.html');

    try {
        let html = fs.readFileSync(indexPath, 'utf8');

        // Inject environment variables into the HTML
        const envData = {
            NODE_ENV: config.nodeEnv,
            IS_STAGING: config.nodeEnv === 'staging',
            IS_PRODUCTION: config.nodeEnv === 'production',
            API_URL: `http://localhost:${config.port}`,
            FIREBASE_PROJECT: config.firebase.projectId
        };

        // Replace placeholder or add script with environment data
        const envScript = `
        <script>
            window.ENV = ${JSON.stringify(envData)};
            console.log('Environment loaded:', window.ENV);
        </script>`;

        // Insert the script before the closing </head> tag
        html = html.replace('</head>', `${envScript}\n</head>`);

        res.set('Content-Type', 'text/html');
        res.send(html);
    } catch (error) {
        console.error('Error serving index.html:', error);
        res.status(500).send('Error loading page');
    }
});

// Health check
app.get('/health', async (req, res) => {
    const startTime = Date.now();
    
    // Check if request is from a browser (wants HTML)
    const wantsHtml = req.headers.accept && req.headers.accept.includes('text/html');
    
    const healthData = {
        status: 'OK',
        timestamp: new Date().toISOString(),
        environment: config.nodeEnv,
        uptime: process.uptime(),
        services: {
            server: { status: 'OK', message: 'Server is running' },
            firebase: { status: 'Unknown', message: 'Checking connection...' },
            email: { status: 'Unknown', message: 'Checking email service...' }
        }
    };

    // Test Firebase connection
    try {
        const db = admin.firestore();
        await db.collection('health_check').limit(1).get();
        healthData.services.firebase = { status: 'OK', message: `Connected to ${config.firebase.projectId}` };
    } catch (error) {
        healthData.services.firebase = { status: 'ERROR', message: `Firebase connection failed: ${error.message}` };
        healthData.status = 'DEGRADED';
    }

    // Test Email service
    try {
        const EmailService = require('./services/emailService');
        const emailService = new EmailService();
        const emailStatus = await emailService.testConnection();
        healthData.services.email = emailStatus ? 
            { status: 'OK', message: 'Email service ready' } : 
            { status: 'ERROR', message: 'Email service not ready' };
        
        if (!emailStatus) {
            healthData.status = 'DEGRADED';
        }
    } catch (error) {
        healthData.services.email = { status: 'ERROR', message: `Email service error: ${error.message}` };
        healthData.status = 'DEGRADED';
    }

    healthData.responseTime = Date.now() - startTime;

    if (wantsHtml) {
        // Return HTML page for browser requests
        const htmlPage = `
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ShareDance - Health Status</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
        }
        .container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 2rem;
            max-width: 600px;
            width: 90%;
            margin: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 2rem;
        }
        .logo {
            font-size: 2.5rem;
            font-weight: bold;
            background: linear-gradient(45deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 0.5rem;
        }
        .status-badge {
            display: inline-block;
            padding: 0.5rem 1rem;
            border-radius: 25px;
            font-weight: bold;
            font-size: 0.9rem;
            margin-bottom: 1rem;
        }
        .status-ok { background: #4CAF50; color: white; }
        .status-degraded { background: #FF9800; color: white; }
        .status-error { background: #f44336; color: white; }
        .services {
            margin: 1.5rem 0;
        }
        .service-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1rem;
            margin: 0.5rem 0;
            background: #f8f9fa;
            border-radius: 10px;
            border-left: 4px solid #ddd;
        }
        .service-item.ok { border-left-color: #4CAF50; }
        .service-item.error { border-left-color: #f44336; }
        .service-name {
            font-weight: 600;
            text-transform: capitalize;
        }
        .service-status {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .status-icon {
            width: 12px;
            height: 12px;
            border-radius: 50%;
        }
        .status-icon.ok { background: #4CAF50; }
        .status-icon.error { background: #f44336; }
        .service-message {
            font-size: 0.85rem;
            color: #666;
            margin-top: 0.25rem;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
            margin-top: 1.5rem;
        }
        .info-item {
            background: #f8f9fa;
            padding: 1rem;
            border-radius: 10px;
            text-align: center;
        }
        .info-label {
            font-size: 0.8rem;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .info-value {
            font-size: 1.2rem;
            font-weight: bold;
            color: #333;
            margin-top: 0.25rem;
        }
        .refresh-btn {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 0.75rem 1.5rem;
            border-radius: 25px;
            cursor: pointer;
            font-weight: 600;
            margin-top: 1rem;
            width: 100%;
            transition: transform 0.2s;
        }
        .refresh-btn:hover {
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">ShareDance</div>
            <h2>System Health Status</h2>
            <div class="status-badge status-${healthData.status.toLowerCase()}">
                ${healthData.status}
            </div>
        </div>
        
        <div class="services">
            <h3>Services Status</h3>
            ${Object.entries(healthData.services).map(([name, service]) => `
                <div class="service-item ${service.status.toLowerCase()}">
                    <div>
                        <div class="service-name">${name}</div>
                        <div class="service-message">${service.message}</div>
                    </div>
                    <div class="service-status">
                        <div class="status-icon ${service.status.toLowerCase()}"></div>
                        <span>${service.status}</span>
                    </div>
                </div>
            `).join('')}
        </div>
        
        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">Environment</div>
                <div class="info-value">${healthData.environment}</div>
            </div>
            <div class="info-item">
                <div class="info-label">Uptime</div>
                <div class="info-value">${Math.floor(healthData.uptime / 3600)}h ${Math.floor((healthData.uptime % 3600) / 60)}m</div>
            </div>
            <div class="info-item">
                <div class="info-label">Response Time</div>
                <div class="info-value">${healthData.responseTime}ms</div>
            </div>
            <div class="info-item">
                <div class="info-label">Last Check</div>
                <div class="info-value">${new Date().toLocaleTimeString('es-ES')}</div>
            </div>
        </div>
        
        <button class="refresh-btn" onclick="window.location.reload()">
            🔄 Refresh Status
        </button>
    </div>
</body>
</html>`;
        
        res.setHeader('Content-Type', 'text/html');
        res.status(healthData.status === 'OK' ? 200 : 503).send(htmlPage);
    } else {
        // Return JSON for API requests
        res.status(healthData.status === 'OK' ? 200 : 503).json(healthData);
    }
});

// Import routes AFTER Firebase initialization
const reservationRoutes = require('./routes/reservations');
const reportsRoutes = require('./routes/reports');
const notificationsRoutes = require('./routes/notifications');
const webhooksRoutes = require('./routes/webhooks');
const invitationRoutes = require('./routes/invitations');

// Import scheduled jobs
require('./jobs/cronJobs');

// Routes
app.use('/api/reservations', reservationRoutes);
app.use('/api/reports', reportsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/webhooks', webhooksRoutes);
app.use('/api/invitations', invitationRoutes);

// Global error handler
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({
        error: 'Internal server error',
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Endpoint not found',
        path: req.originalUrl,
        timestamp: new Date().toISOString()
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 ShareDance Server running on port ${PORT}`);
    console.log(`🌍 Environment: ${config.nodeEnv}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
});

module.exports = app;
