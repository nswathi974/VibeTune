const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { SeparationService, AUTHORIZED_TRACKS } = require('../services/separationService');

/**
 * Flexible authentication middleware:
 * Supports Bearer JWT authentication for logged-in users,
 * and allows guest explorers (matching VibeTune guest access).
 */
const flexibleAuth = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];
  }

  // Handle guest token or guest header
  if (
    token === 'guest_jwt_token' ||
    token === 'guest_session' ||
    req.headers['x-guest-mode'] === 'true'
  ) {
    req.user = null;
    req.isGuest = true;
    return next();
  }

  if (token) {
    try {
      const decoded = jwt.verify(
        token,
        process.env.JWT_SECRET || 'vibetune_fallback_secret_key'
      );
      req.user = await User.findById(decoded.id).select('-password');
      req.isGuest = false;
      return next();
    } catch (err) {
      // If token is invalid/expired but request indicated guest mode, fallback gracefully
      if (req.headers['x-guest-mode'] === 'true') {
        req.user = null;
        req.isGuest = true;
        return next();
      }
      return res.status(401).json({
        success: false,
        message: 'Not authorized, token invalid or expired.',
      });
    }
  }

  // Allow guest exploration when no credentials supplied
  req.user = null;
  req.isGuest = true;
  return next();
};

/**
 * @route   POST /api/separation/jobs
 * @desc    Submit a song for AI vocal separation (asynchronous)
 * @access  Protected (Authenticated or Guest)
 */
router.post('/jobs', flexibleAuth, async (req, res) => {
  try {
    const { songId } = req.body;

    if (!songId) {
      return res.status(400).json({
        success: false,
        message: 'Song ID is required',
      });
    }

    const result = await SeparationService.createJob({
      songId,
      userId: req.user ? req.user._id : null,
      isGuest: req.isGuest || false,
    });

    const statusCode = result.cached ? 200 : 202;
    res.status(statusCode).json({
      success: true,
      cached: result.cached,
      message: result.cached
        ? 'Instrumental track retrieved from verified cache.'
        : 'AI vocal separation job initiated.',
      job: {
        jobId: result.job.jobId,
        songId: result.job.songId,
        songTitle: result.job.songTitle,
        status: result.job.status,
        progress: result.job.progress,
        instrumentalUrl: result.job.instrumentalUrl,
        cached: result.cached,
        createdAt: result.job.createdAt,
      },
    });
  } catch (err) {
    const status = err.statusCode || 500;
    res.status(status).json({
      success: false,
      message: err.message,
    });
  }
});

/**
 * @route   GET /api/separation/jobs/:jobId
 * @desc    Get status of an AI separation job
 * @access  Protected (Authenticated or Guest)
 */
router.get('/jobs/:jobId', flexibleAuth, async (req, res) => {
  try {
    const { jobId } = req.params;
    const job = await SeparationService.getJob(jobId);

    if (!job) {
      return res.status(404).json({
        success: false,
        message: `Separation job "${jobId}" was not found.`,
      });
    }

    res.json({
      success: true,
      job: {
        jobId: job.jobId,
        songId: job.songId,
        songTitle: job.songTitle,
        status: job.status,
        progress: job.progress,
        instrumentalUrl: job.instrumentalUrl,
        errorMessage: job.errorMessage,
        executionTimeMs: job.executionTimeMs,
        completedAt: job.completedAt,
        createdAt: job.createdAt,
      },
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

/**
 * @route   GET /api/separation/status/song/:songId
 * @desc    Get latest separation status or cached instrumental for a song
 * @access  Protected (Authenticated or Guest)
 */
router.get('/status/song/:songId', flexibleAuth, async (req, res) => {
  try {
    const { songId } = req.params;
    const job = await SeparationService.getSongStatus(songId);

    if (!job) {
      return res.json({
        success: true,
        hasSeparatedAudio: false,
        status: 'not_requested',
      });
    }

    res.json({
      success: true,
      hasSeparatedAudio: job.status === 'completed',
      status: job.status,
      job: {
        jobId: job.jobId,
        songId: job.songId,
        status: job.status,
        progress: job.progress,
        instrumentalUrl: job.instrumentalUrl,
      },
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

/**
 * @route   GET /api/separation/authorized-tracks
 * @desc    List all tracks authorized for AI vocal separation
 * @access  Public
 */
router.get('/authorized-tracks', (req, res) => {
  res.json({
    success: true,
    count: Object.keys(AUTHORIZED_TRACKS).length,
    tracks: Object.values(AUTHORIZED_TRACKS).map((t) => ({
      songId: t.songId,
      title: t.title,
      language: t.language,
      durationSeconds: t.durationSeconds,
    })),
  });
});

module.exports = router;
