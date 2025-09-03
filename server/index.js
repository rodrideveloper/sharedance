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
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        environment: config.nodeEnv,
        firebase: {
            projectId: config.firebase.projectId
        }
    });
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
