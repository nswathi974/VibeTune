const mongoose = require('mongoose');

/**
 * SeparationJob Schema for VibeTune
 * Tracks asynchronous AI vocal separation jobs (e.g., Replicate Demucs),
 * records caching status, execution metrics, and file locations.
 * Audio binaries are stored on filesystem/object storage, never as blobs in MongoDB.
 */
const separationJobSchema = new mongoose.Schema(
  {
    jobId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    isGuest: {
      type: Boolean,
      default: false,
    },
    songId: {
      type: String,
      required: [true, 'Song ID is required'],
      index: true,
    },
    songTitle: {
      type: String,
      required: [true, 'Song Title is required'],
    },
    audioSource: {
      type: String,
      required: [true, 'Audio source path is required'],
    },
    provider: {
      type: String,
      default: 'replicate-demucs',
      enum: ['replicate-demucs', 'mock-demucs'],
    },
    providerPredictionId: {
      type: String,
      default: null,
    },
    status: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed', 'canceled'],
      default: 'pending',
      index: true,
    },
    instrumentalUrl: {
      type: String,
      default: null,
    },
    instrumentalPath: {
      type: String,
      default: null,
    },
    vocalsUrl: {
      type: String,
      default: null,
    },
    progress: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },
    errorMessage: {
      type: String,
      default: null,
    },
    executionTimeMs: {
      type: Number,
      default: null,
    },
    cached: {
      type: Boolean,
      default: false,
    },
    metadata: {
      durationSeconds: Number,
      fileSizeBytes: Number,
      format: String,
      stems: [String],
    },
    completedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for fast cache lookup by songId and status
separationJobSchema.index({ songId: 1, status: 1 });

module.exports = mongoose.model('SeparationJob', separationJobSchema);

