const admin = require('firebase-admin');

// Authentication middleware
const authenticateUser = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'Authorization token required' });
        }

        const token = authHeader.split('Bearer ')[1];

        // Verify Firebase token
        const decodedToken = await admin.auth().verifyIdToken(token);

        // Get user data from Firestore
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(decodedToken.uid)
            .get();

        if (!userDoc.exists) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Attach user data to request
        req.user = {
            uid: decodedToken.uid,
            email: decodedToken.email,
            ...userDoc.data()
        };

        next();

    } catch (error) {
        console.error('Authentication error:', error);

        if (error.code === 'auth/id-token-expired') {
            return res.status(401).json({ error: 'Token expired' });
        }

        if (error.code === 'auth/argument-error') {
            return res.status(401).json({ error: 'Invalid token format' });
        }

        return res.status(401).json({ error: 'Invalid or expired token' });
    }
};

// Admin-only middleware
const requireAdmin = async (req, res, next) => {
    await authenticateUser(req, res, () => {
        if (!req.user || req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }
        next();
    });
};

// Teacher or Admin middleware
const requireTeacherOrAdmin = async (req, res, next) => {
    await authenticateUser(req, res, () => {
        if (!req.user || (req.user.role !== 'teacher' && req.user.role !== 'admin')) {
            return res.status(403).json({ error: 'Teacher or admin access required' });
        }
        next();
    });
};

// Simple validation middleware
const validateRequest = (schema) => {
    return (req, res, next) => {
        const errors = [];

        for (const [field, rules] of Object.entries(schema)) {
            const value = req.body[field];

            // Check required fields
            if (rules.required && (value === undefined || value === null || value === '')) {
                errors.push(`${field} is required`);
                continue;
            }

            // Skip validation if field is not required and not provided
            if (!rules.required && (value === undefined || value === null)) {
                continue;
            }

            // Type validation
            if (rules.type) {
                switch (rules.type) {
                    case 'string':
                        if (typeof value !== 'string') {
                            errors.push(`${field} must be a string`);
                        }
                        break;
                    case 'number':
                        if (typeof value !== 'number') {
                            errors.push(`${field} must be a number`);
                        }
                        break;
                    case 'boolean':
                        if (typeof value !== 'boolean') {
                            errors.push(`${field} must be a boolean`);
                        }
                        break;
                    case 'array':
                        if (!Array.isArray(value)) {
                            errors.push(`${field} must be an array`);
                        }
                        break;
                    case 'object':
                        if (typeof value !== 'object' || Array.isArray(value)) {
                            errors.push(`${field} must be an object`);
                        }
                        break;
                }
            }

            // Enum validation
            if (rules.enum && !rules.enum.includes(value)) {
                errors.push(`${field} must be one of: ${rules.enum.join(', ')}`);
            }

            // Min/Max length for strings
            if (rules.minLength && typeof value === 'string' && value.length < rules.minLength) {
                errors.push(`${field} must be at least ${rules.minLength} characters long`);
            }

            if (rules.maxLength && typeof value === 'string' && value.length > rules.maxLength) {
                errors.push(`${field} must be at most ${rules.maxLength} characters long`);
            }

            // Min/Max value for numbers
            if (rules.min !== undefined && typeof value === 'number' && value < rules.min) {
                errors.push(`${field} must be at least ${rules.min}`);
            }

            if (rules.max !== undefined && typeof value === 'number' && value > rules.max) {
                errors.push(`${field} must be at most ${rules.max}`);
            }

            // Email validation
            if (rules.email && typeof value === 'string') {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(value)) {
                    errors.push(`${field} must be a valid email address`);
                }
            }
        }

        if (errors.length > 0) {
            return res.status(400).json({
                error: 'Validation failed',
                details: errors
            });
        }

        next();
    };
};

// Rate limiting middleware (simple implementation)
const rateLimitMap = new Map();

const rateLimit = (options = {}) => {
    const {
        windowMs = 15 * 60 * 1000, // 15 minutes
        max = 100, // 100 requests per window
        message = 'Too many requests, please try again later'
    } = options;

    return (req, res, next) => {
        const key = req.ip;
        const now = Date.now();

        if (!rateLimitMap.has(key)) {
            rateLimitMap.set(key, { count: 1, resetTime: now + windowMs });
            return next();
        }

        const data = rateLimitMap.get(key);

        if (now > data.resetTime) {
            // Reset the window
            rateLimitMap.set(key, { count: 1, resetTime: now + windowMs });
            return next();
        }

        if (data.count >= max) {
            return res.status(429).json({ error: message });
        }

        data.count++;
        next();
    };
};

module.exports = {
    authenticateUser,
    requireAdmin,
    requireTeacherOrAdmin,
    validateRequest,
    rateLimit
};
