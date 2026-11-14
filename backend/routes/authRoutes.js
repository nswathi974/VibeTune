const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../models/User');
const { protect, authorize, checkUserOwnership } = require('../middleware/auth');

const router = express.Router();

/**
 * Check if MongoDB Atlas is ready; return 503 immediately if disconnected
 */
const checkDbConnection = (res) => {
  if (mongoose.connection.readyState !== 1) {
    res.status(503).json({
      success: false,
      message: 'MongoDB Atlas is currently disconnected. Please check database connection.',
    });
    return false;
  }
  return true;
};

/**
 * Generate JWT token signed with secret from environment variables
 */
const generateToken = (id) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    console.warn('⚠️ Warning: JWT_SECRET is not set in environment variables. Using fallback.');
  }
  return jwt.sign(
    { id },
    secret || 'vibetune_fallback_secret_key',
    {
      expiresIn: process.env.JWT_EXPIRE || '30d',
    }
  );
};

// Email validation helper regex (supports modern TLDs)
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * @route   POST /api/auth/signup (or /api/auth/register)
 * @desc    Register a new user, hash password with bcryptjs, return JWT.
 *          SECURITY: Role is strictly set to 'user'. Role injection via body is completely ignored.
 * @access  Public
 */
const handleSignup = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Validate presence of required fields
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, and password.',
      });
    }

    const trimmedName = name.trim();
    const normalizedEmail = email.trim().toLowerCase();

    if (trimmedName.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Name cannot be empty.',
      });
    }

    // Validate email format
    if (!EMAIL_REGEX.test(normalizedEmail)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid email address.',
      });
    }

    // Validate password length
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long.',
      });
    }

    if (!checkDbConnection(res)) return;

    // Check if user already exists with this email
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email is already registered. Please login instead.',
      });
    }

    // Create new user (Role is strictly locked to 'user' to prevent privilege escalation)
    const user = await User.create({
      name: trimmedName,
      email: normalizedEmail,
      password,
      role: 'user',
    });

    // Generate JWT
    const token = generateToken(user._id);

    return res.status(201).json({
      success: true,
      message: 'User registered successfully.',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    console.error('Signup Error:', error);

    // Handle MongoDB duplicate key error (code 11000)
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Email is already registered. Please login instead.',
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Server error during registration. Please try again.',
    });
  }
};

router.post('/signup', handleSignup);
router.post('/register', handleSignup); // Alias for convenience

/**
 * @route   POST /api/auth/login
 * @desc    Authenticate user, verify bcrypt hash, and return JWT
 * @access  Public
 */
router.post('/login', async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    const { email, password } = req.body;

    // Validate required fields
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password.',
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Find user by email and explicitly include password field for verification
    const user = await User.findOne({ email: normalizedEmail }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    // Verify password with bcryptjs
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    // Generate JWT
    const token = generateToken(user._id);

    return res.status(200).json({
      success: true,
      message: 'Login successful.',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    console.error('Login Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error during login. Please try again.',
    });
  }
});

/**
 * @route   POST /api/auth/logout
 * @desc    Logout user / acknowledge session termination
 * @access  Public
 */
router.post('/logout', (req, res) => {
  return res.status(200).json({
    success: true,
    message: 'Logged out successfully.',
  });
});

/**
 * @route   GET /api/auth/me
 * @desc    Get currently logged in user profile
 * @access  Private (Requires valid JWT Bearer token)
 */
router.get('/me', protect, async (req, res) => {
  res.status(200).json({
    success: true,
    user: {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role,
      createdAt: req.user.createdAt,
    },
  });
});

/**
 * @route   PUT /api/auth/profile
 * @desc    Update user's own profile (name, email)
 *          SECURITY: Role cannot be modified through this endpoint.
 * @access  Private (Requires valid JWT Bearer token)
 */
router.put('/profile', protect, async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    const { name, email } = req.body;
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    if (name && name.trim().length > 0) {
      user.name = name.trim();
    }

    if (email && email.trim().toLowerCase() !== user.email) {
      const normalizedEmail = email.trim().toLowerCase();
      if (!EMAIL_REGEX.test(normalizedEmail)) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid email address.',
        });
      }
      const existing = await User.findOne({ email: normalizedEmail });
      if (existing) {
        return res.status(400).json({
          success: false,
          message: 'Email is already in use by another account.',
        });
      }
      user.email = normalizedEmail;
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('Update Profile Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error updating profile.',
    });
  }
});

/**
 * @route   GET /api/auth/user/:userId/data
 * @desc    Demonstrate user-specific data isolation:
 *          Returns protected user data ONLY if requester owns the resource or is admin.
 * @access  Private + Ownership Check
 */
router.get('/user/:userId/data', protect, checkUserOwnership('userId'), async (req, res) => {
  const targetUser = await User.findById(req.params.userId).select('-password');
  if (!targetUser) {
    return res.status(404).json({ success: false, message: 'User not found.' });
  }

  return res.status(200).json({
    success: true,
    message: 'User data retrieved with verified ownership authorization.',
    data: {
      userId: targetUser._id,
      name: targetUser.name,
      email: targetUser.email,
      role: targetUser.role,
      accessedBy: req.user.email,
      requesterRole: req.user.role,
    },
  });
});

/**
 * ============================================================================
 * ADMIN ROLE PROTECTED ROUTES
 * Only users with role: 'admin' can access these endpoints
 * ============================================================================
 */

/**
 * @route   GET /api/auth/admin/users
 * @desc    Get all registered users with their roles (Admin only)
 * @access  Private (Admin only)
 */
router.get('/admin/users', protect, authorize('admin'), async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    return res.status(200).json({
      success: true,
      count: users.length,
      users,
    });
  } catch (error) {
    console.error('Admin Get Users Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error fetching user list.',
    });
  }
});

/**
 * @route   PUT /api/auth/admin/users/:id/role
 * @desc    Update a user's role (Admin only)
 * @access  Private (Admin only)
 */
router.put('/admin/users/:id/role', protect, authorize('admin'), async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    const { role } = req.body;
    if (!role || !['user', 'admin'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid role. Must be either "user" or "admin".',
      });
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    user.role = role;
    await user.save();

    return res.status(200).json({
      success: true,
      message: `User role updated to ${role} successfully.`,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('Admin Update Role Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error updating user role.',
    });
  }
});

module.exports = router;
