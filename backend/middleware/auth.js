const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * Middleware to protect routes and verify JWT token.
 * Extracts Bearer token from Authorization header and attaches authenticated user to req.user.
 */
const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized, no token provided.',
    });
  }

  try {
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || 'vibetune_fallback_secret_key'
    );

    req.user = await User.findById(decoded.id).select('-password');

    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'User belonging to this token no longer exists.',
      });
    }

    return next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token has expired. Please log in again.',
      });
    }
    return res.status(401).json({
      success: false,
      message: 'Not authorized, token invalid or expired.',
    });
  }
};

/**
 * Role-based authorization middleware.
 * Usage: router.get('/admin', protect, authorize('admin'), handler)
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required before authorization check.',
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `User role '${req.user.role}' is not authorized to access this resource.`,
      });
    }

    next();
  };
};

/**
 * Resource ownership middleware to prevent users from accessing or modifying another user's data.
 * Checks whether the target userId (from params or body) matches the authenticated user, or if the requester is an admin.
 */
const checkUserOwnership = (paramKey = 'userId') => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
    }

    // Admins have supervisory override
    if (req.user.role === 'admin') {
      return next();
    }

    const targetUserId = req.params[paramKey] || req.body[paramKey];
    if (!targetUserId || targetUserId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "Access denied: You are not authorized to view or modify another user's resources.",
      });
    }

    next();
  };
};

module.exports = {
  protect,
  authorize,
  checkUserOwnership,
};
