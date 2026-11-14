const mongoose = require('mongoose');

/**
 * Playlist Schema for VibeTune
 * Manages user-specific custom playlists with strict user ownership isolation.
 */
const playlistSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Playlist must belong to a user'],
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Please provide a playlist name'],
      trim: true,
      maxlength: [100, 'Playlist name cannot exceed 100 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [300, 'Description cannot exceed 300 characters'],
      default: '',
    },
    songs: {
      type: [String],
      default: [],
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: function (doc, ret) {
        ret.id = ret._id.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Compound index to help query playlists by user ordered by recent activity
playlistSchema.index({ user: 1, updatedAt: -1 });

module.exports = mongoose.model('Playlist', playlistSchema);

