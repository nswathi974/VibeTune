
const dns = require('dns');
// Configure reliable DNS servers for SRV resolution to prevent Windows Wi-Fi querySrv EBADRESP errors
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (dnsErr) {
  console.warn(`DNS server configuration note: ${dnsErr.message}`);
}

require('dotenv').config();

const path = require('path');
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const separationRoutes = require('./routes/separationRoutes');
const playlistRoutes = require('./routes/playlistRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Serve separated audio files statically from secure local cache
app.use('/media/separated', express.static(path.join(__dirname, 'media', 'separated')));

// Initialize MongoDB Connection (in test mode, tests control lifecycle)
if (process.env.NODE_ENV !== 'test') {
  connectDB();
}

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/separation', separationRoutes);
app.use('/api/playlists', playlistRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to VibeTune Backend API',
    version: '1.2.0',
    endpoints: {
      health: '/api/health',
      signup: 'POST /api/auth/signup',
      login: 'POST /api/auth/login',
      me: 'GET /api/auth/me (Protected)',
      playlists: '/api/playlists (Protected)',
      separationJobs: 'POST /api/separation/jobs (Protected)',
      separationStatus: 'GET /api/separation/jobs/:jobId (Protected)',
      authorizedTracks: 'GET /api/separation/authorized-tracks',
    },
  });
});

/**
 * Health check endpoint: verifies server uptime & MongoDB connection
 * Used by Flutter client, monitoring, and MCA project demonstrations
 */
app.get('/api/health', (req, res) => {
  const dbState = mongoose.connection.readyState;
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };

  const isHealthy = dbState === 1;

  res.status(isHealthy ? 200 : 503).json({
    success: true,
    service: 'VibeTune Backend API',
    uptime: `${process.uptime().toFixed(1)}s`,
    timestamp: new Date().toISOString(),
    database: {
      type: 'MongoDB Atlas',
      status: states[dbState] || 'unknown',
      connected: isHealthy,
      name: mongoose.connection.name || null,
      host: mongoose.connection.host || null,
    },
    system: {
      nodeVersion: process.version,
      platform: process.platform,
    },
  });
});

// Start Express Server
let server;
if (process.env.NODE_ENV !== 'test' || require.main === module) {
  server = app.listen(PORT, '0.0.0.0', () => {
    console.log('====================================================');
    console.log(`🎵 VibeTune Server is running on port ${PORT}`);
    console.log(`   Local URL:    http://localhost:${PORT}`);
    console.log(`   Health Check: http://localhost:${PORT}/api/health`);
    console.log('====================================================');
  });
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error(`Unhandled Rejection: ${err.message}`);
});

module.exports = { app, server };
