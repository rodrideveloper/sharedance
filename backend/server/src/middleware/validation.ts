import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import Joi from 'joi';

// Extend Request interface to include user
declare global {
    namespace Express {
        interface Request {
            user?: {
                uid: string;
                email?: string;
                role?: string;
            };
        }
    }
}

// Authenticate user middleware
export const authenticateUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({ error: 'No token provided' });
            return;
        }

        const token = authHeader.substring(7); // Remove 'Bearer ' prefix

        // Verify Firebase token
        const decodedToken = await admin.auth().verifyIdToken(token);

        // Get user data from Firestore
        const userDoc = await admin.firestore().collection('users').doc(decodedToken.uid).get();

        if (!userDoc.exists) {
            res.status(401).json({ error: 'User not found' });
            return;
        }

        const userData = userDoc.data()!;

        req.user = {
            uid: decodedToken.uid,
            email: decodedToken.email,
            role: userData.role
        };

        next();
    } catch (error) {
        console.error('Authentication error:', error);
        res.status(401).json({ error: 'Invalid token' });
        return;
    }
};

// Validate request body middleware
export const validateRequest = (schema: Joi.ObjectSchema) => {
    return (req: Request, res: Response, next: NextFunction): void => {
        const { error } = schema.validate(req.body);

        if (error) {
            res.status(400).json({
                error: 'Validation Error',
                details: error.details.map((detail: any) => ({
                    message: detail.message,
                    path: detail.path
                }))
            });
            return;
        }

        next();
    };
};

// Role-based authorization middleware
export const requireRole = (roles: string[]) => {
    return (req: Request, res: Response, next: NextFunction): void => {
        if (!req.user) {
            res.status(401).json({ error: 'Not authenticated' });
            return;
        }

        if (!roles.includes(req.user.role || '')) {
            res.status(403).json({ error: 'Insufficient permissions' });
            return;
        }

        next();
    };
};

// Admin only middleware
export const requireAdmin = requireRole(['admin']);

// Teacher or Admin middleware
export const requireTeacherOrAdmin = requireRole(['teacher', 'admin']);