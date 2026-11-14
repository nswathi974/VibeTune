const express = require('express');
const mongoose = require('mongoose');
const Playlist = require('../models/Playlist');
const { protect } = require('../middleware/auth');

const router = express.Router();

/**
 * Check if MongoDB Atlas is ready; return 503 if disconnected
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

// All playlist routes require authentication
router.use(protect);

/**
 * @route   GET /api/playlists
 * @desc    Get all playlists owned by the authenticated user
 * @access  Private (Owner scoped)
 */
router.get('/', async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    const playlists = await Playlist.find({ user: req.user._id }).sort({ updatedAt: -1 });

    return res.status(200).json({
      success: true,
      count: playlists.length,
      playlists: playlists.map((p) => ({
        id: p._id.toString(),
        name: p.name,
        description: p.description,
        songCount: p.songs.length,
        songs: p.songs,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      })),
    });
  } catch (error) {
    console.error('Get Playlists Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving playlists.',
    });
  }
});

/**
 * @route   POST /api/playlists
 * @desc    Create a new playlist for the authenticated user
 * @access  Private
 */
router.post('/', async (req, res) => {
  try {
    const { name, description, songs } = req.body;

    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a non-empty playlist name.',
      });
    }

    const trimmedName = name.trim();
    if (trimmedName.length > 100) {
      return res.status(400).json({
        success: false,
        message: 'Playlist name cannot exceed 100 characters.',
      });
    }

    if (!checkDbConnection(res)) return;

    // Sanitize initial songs list if provided
    let initialSongs = [];
    if (Array.isArray(songs)) {
      initialSongs = songs.filter((s) => typeof s === 'string' && s.trim().length > 0);
    }

    // Ownership security: The playlist ALWAYS belongs strictly to req.user._id (from JWT)
    const playlist = await Playlist.create({
      user: req.user._id,
      name: trimmedName,
      description: typeof description === 'string' ? description.trim() : '',
      songs: initialSongs,
    });

    return res.status(201).json({
      success: true,
      message: 'Playlist created successfully.',
      playlist: {
        id: playlist._id.toString(),
        name: playlist.name,
        description: playlist.description,
        songCount: playlist.songs.length,
        songs: playlist.songs,
        createdAt: playlist.createdAt,
        updatedAt: playlist.updatedAt,
      },
    });
  } catch (error) {
    console.error('Create Playlist Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error creating playlist.',
    });
  }
});

/**
 * @route   GET /api/playlists/:id
 * @desc    Get a single playlist by ID (Strict ownership check)
 * @access  Private (Owner or Admin)
 */
router.get('/:id', async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid playlist ID format.',
      });
    }

    const playlist = await Playlist.findById(req.params.id);
    if (!playlist) {
      return res.status(404).json({
        success: false,
        message: 'Playlist not found.',
      });
    }

    // Strict ownership verification: Only owner or admin may view
    if (playlist.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not authorized to view another user’s playlist.',
      });
    }

    return res.status(200).json({
      success: true,
      playlist: {
        id: playlist._id.toString(),
        name: playlist.name,
        description: playlist.description,
        songCount: playlist.songs.length,
        songs: playlist.songs,
        createdAt: playlist.createdAt,
        updatedAt: playlist.updatedAt,
      },
    });
  } catch (error) {
    console.error('Get Playlist By ID Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving playlist.',
    });
  }
});

/**
 * @route   PUT /api/playlists/:id
 * @desc    Rename or update a playlist's details (Strict ownership check)
 * @access  Private (Owner only)
 */
router.put('/:id', async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid playlist ID format.',
      });
    }

    const playlist = await Playlist.findById(req.params.id);
    if (!playlist) {
      return res.status(404).json({
        success: false,
        message: 'Playlist not found.',
      });
    }

    // Strict ownership verification
    if (playlist.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not authorized to modify another user’s playlist.',
      });
    }

    const { name, description } = req.body;

    if (name !== undefined) {
      if (typeof name !== 'string' || name.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Playlist name cannot be empty.',
        });
      }
      if (name.trim().length > 100) {
        return res.status(400).json({
          success: false,
          message: 'Playlist name cannot exceed 100 characters.',
        });
      }
      playlist.name = name.trim();
    }

    if (description !== undefined) {
      playlist.description = typeof description === 'string' ? description.trim() : '';
    }

    await playlist.save();

    return res.status(200).json({
      success: true,
      message: 'Playlist updated successfully.',
      playlist: {
        id: playlist._id.toString(),
        name: playlist.name,
        description: playlist.description,
        songCount: playlist.songs.length,
        songs: playlist.songs,
        createdAt: playlist.createdAt,
        updatedAt: playlist.updatedAt,
      },
    });
  } catch (error) {
    console.error('Update Playlist Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error updating playlist.',
    });
  }
});

/**
 * @route   DELETE /api/playlists/:id
 * @desc    Delete a playlist (Strict ownership check)
 * @access  Private (Owner only)
 */
router.delete('/:id', async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid playlist ID format.',
      });
    }

    const playlist = await Playlist.findById(req.params.id);
    if (!playlist) {
      return res.status(404).json({
        success: false,
        message: 'Playlist not found.',
      });
    }

    // Strict ownership verification
    if (playlist.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not authorized to delete another user’s playlist.',
      });
    }

    await Playlist.deleteOne({ _id: req.params.id });

    return res.status(200).json({
      success: true,
      message: 'Playlist deleted successfully.',
    });
  } catch (error) {
    console.error('Delete Playlist Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error deleting playlist.',
    });
  }
});

/**
 * @route   POST /api/playlists/:id/songs
 * @desc    Add a song to playlist (Strict ownership check)
 * @access  Private (Owner only)
 */
router.post('/:id/songs', async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid playlist ID format.',
      });
    }

    const playlist = await Playlist.findById(req.params.id);
    if (!playlist) {
      return res.status(404).json({
        success: false,
        message: 'Playlist not found.',
      });
    }

    // Strict ownership verification
    if (playlist.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not authorized to modify another user’s playlist.',
      });
    }

    const { songId } = req.body;
    if (!songId || typeof songId !== 'string' || songId.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid songId string.',
      });
    }

    const cleanSongId = songId.trim();

    // Prevent duplicate entries
    if (playlist.songs.includes(cleanSongId)) {
      return res.status(400).json({
        success: false,
        message: 'Song is already in this playlist.',
      });
    }

    playlist.songs.push(cleanSongId);
    await playlist.save();

    return res.status(200).json({
      success: true,
      message: 'Song added to playlist.',
      songCount: playlist.songs.length,
      songs: playlist.songs,
    });
  } catch (error) {
    console.error('Add Song Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error adding song to playlist.',
    });
  }
});

/**
 * @route   DELETE /api/playlists/:id/songs/:songId
 * @desc    Remove a song from playlist (Strict ownership check)
 * @access  Private (Owner only)
 */
router.delete('/:id/songs/:songId', async (req, res) => {
  if (!checkDbConnection(res)) return;

  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid playlist ID format.',
      });
    }

    const playlist = await Playlist.findById(req.params.id);
    if (!playlist) {
      return res.status(404).json({
        success: false,
        message: 'Playlist not found.',
      });
    }

    // Strict ownership verification
    if (playlist.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not authorized to modify another user’s playlist.',
      });
    }

    const songIdToRemove = req.params.songId;
    if (!playlist.songs.includes(songIdToRemove)) {
      return res.status(404).json({
        success: false,
        message: 'Song not found in this playlist.',
      });
    }

    playlist.songs = playlist.songs.filter((s) => s !== songIdToRemove);
    await playlist.save();

    return res.status(200).json({
      success: true,
      message: 'Song removed from playlist.',
      songCount: playlist.songs.length,
      songs: playlist.songs,
    });
  } catch (error) {
    console.error('Remove Song Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error removing song from playlist.',
    });
  }
});

module.exports = router;

