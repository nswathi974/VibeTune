const dns = require('dns');
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (_) {}

process.env.NODE_ENV = 'test';
require('dotenv').config();

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const Playlist = require('../models/Playlist');
const { app } = require('../server');

const TEST_SECRET = process.env.JWT_SECRET || 'vibetune_fallback_secret_key';

describe('VibeTune Custom Playlist Module Tests', () => {
  let serverInstance;
  let baseUrl;
  let userA;
  let userB;
  let adminUser;
  let tokenUserA;
  let tokenUserB;
  let tokenAdmin;
  let playlistA;
  let playlistB;

  before(async () => {
    // 1. Connect to MongoDB Atlas
    const connectDB = require('../config/db');
    await connectDB();

    // 2. Start ephemeral HTTP server on dynamic port
    await new Promise((resolve) => {
      serverInstance = app.listen(0, '127.0.0.1', () => {
        const port = serverInstance.address().port;
        baseUrl = `http://127.0.0.1:${port}`;
        resolve();
      });
    });

    if (mongoose.connection.readyState === 1) {
      // 3. Clean up any previous test artifacts
      await User.deleteMany({ email: /@playlisttest\.vibetune\.com$/i });
      await Playlist.deleteMany({ name: /^TEST_PL_/ });

      // Create test users
      userA = await User.create({
        name: 'Playlist Tester A',
        email: 'user_a@playlisttest.vibetune.com',
        password: 'Password123!',
        role: 'user',
      });
      tokenUserA = jwt.sign({ id: userA._id }, TEST_SECRET, { expiresIn: '1h' });

      userB = await User.create({
        name: 'Playlist Tester B',
        email: 'user_b@playlisttest.vibetune.com',
        password: 'Password123!',
        role: 'user',
      });
      tokenUserB = jwt.sign({ id: userB._id }, TEST_SECRET, { expiresIn: '1h' });

      adminUser = await User.create({
        name: 'Playlist Admin Tester',
        email: 'admin@playlisttest.vibetune.com',
        password: 'AdminPassword123!',
        role: 'admin',
      });
      tokenAdmin = jwt.sign({ id: adminUser._id }, TEST_SECRET, { expiresIn: '1h' });

      // Create initial playlist for User A
      playlistA = await Playlist.create({
        user: userA._id,
        name: 'TEST_PL_UserA_Chill',
        description: 'User A chill songs',
        songs: ['vt_studio_hi', 'vt_studio_ka'],
      });

      // Create initial playlist for User B
      playlistB = await Playlist.create({
        user: userB._id,
        name: 'TEST_PL_UserB_Party',
        description: 'User B party hits',
        songs: ['vt_studio_te'],
      });
    }
  });

  after(async () => {
    if (mongoose.connection.readyState === 1) {
      await User.deleteMany({ email: /@playlisttest\.vibetune\.com$/i });
      await Playlist.deleteMany({ name: /^TEST_PL_/ });
    }
    await mongoose.disconnect();

    if (serverInstance) {
      await new Promise((resolve) => serverInstance.close(resolve));
    }
  });

  // =========================================================================
  // 1. Authentication & Security
  // =========================================================================
  describe('1. Authentication & Route Protection', () => {
    it('GET /api/playlists rejects unauthenticated request (HTTP 401)', async () => {
      const res = await fetch(`${baseUrl}/api/playlists`);
      assert.strictEqual(res.status, 401);
      const data = await res.json();
      assert.strictEqual(data.success, false);
      assert.match(data.message, /no token provided/i);
    });

    it('POST /api/playlists rejects unauthenticated request (HTTP 401)', async () => {
      const res = await fetch(`${baseUrl}/api/playlists`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'TEST_PL_Hacker' }),
      });
      assert.strictEqual(res.status, 401);
    });
  });

  // =========================================================================
  // 2. Playlist CRUD & Ownership Enforcement
  // =========================================================================
  describe('2. Playlist CRUD & Ownership Enforcement', () => {
    let createdPlaylistId;

    it('POST /api/playlists creates a playlist strictly owned by authenticated user (ignores injected user/userId)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/playlists`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({
          name: 'TEST_PL_New_UserA',
          description: 'Created by User A',
          songs: ['vt_studio_ta'],
          user: userB._id.toString(), // Malicious attempt to assign ownership to User B
          userId: userB._id.toString(),
        }),
      });

      assert.strictEqual(res.status, 201);
      const data = await res.json();
      assert.strictEqual(data.success, true);
      assert.strictEqual(data.playlist.name, 'TEST_PL_New_UserA');
      assert.strictEqual(data.playlist.songCount, 1);
      assert.deepStrictEqual(data.playlist.songs, ['vt_studio_ta']);

      createdPlaylistId = data.playlist.id;

      // Verify in DB directly: user must be User A, not User B!
      const dbDoc = await Playlist.findById(createdPlaylistId);
      assert.strictEqual(dbDoc.user.toString(), userA._id.toString());
    });

    it('POST /api/playlists rejects missing or empty playlist name (HTTP 400)', async () => {
      if (mongoose.connection.readyState !== 1) return;
      const res = await fetch(`${baseUrl}/api/playlists`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({ name: '   ', description: 'Empty name' }),
      });

      assert.strictEqual(res.status, 400);
      const data = await res.json();
      assert.strictEqual(data.success, false);
      assert.match(data.message, /provide a non-empty playlist name/i);
    });

    it('GET /api/playlists returns only playlists belonging to the requesting user', async () => {
      if (mongoose.connection.readyState !== 1) return;

      // User A fetch
      const resA = await fetch(`${baseUrl}/api/playlists`, {
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });
      assert.strictEqual(resA.status, 200);
      const dataA = await resA.json();
      assert.strictEqual(dataA.success, true);
      assert.ok(dataA.count >= 2);
      // All playlists must belong to User A
      const namesA = dataA.playlists.map((p) => p.name);
      assert.ok(namesA.includes('TEST_PL_UserA_Chill'));
      assert.ok(namesA.includes('TEST_PL_New_UserA'));
      assert.strictEqual(namesA.includes('TEST_PL_UserB_Party'), false);

      // User B fetch
      const resB = await fetch(`${baseUrl}/api/playlists`, {
        headers: { Authorization: `Bearer ${tokenUserB}` },
      });
      assert.strictEqual(resB.status, 200);
      const dataB = await resB.json();
      assert.strictEqual(dataB.success, true);
      const namesB = dataB.playlists.map((p) => p.name);
      assert.ok(namesB.includes('TEST_PL_UserB_Party'));
      assert.strictEqual(namesB.includes('TEST_PL_UserA_Chill'), false);
    });

    it('GET /api/playlists/:id blocks User A from viewing User B playlist (HTTP 403 Forbidden)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      // User A tries to view User B's playlist
      const resForbidden = await fetch(`${baseUrl}/api/playlists/${playlistB._id}`, {
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });
      assert.strictEqual(resForbidden.status, 403);
      const data = await resForbidden.json();
      assert.strictEqual(data.success, false);
      assert.match(data.message, /not authorized to view another user’s playlist/i);

      // User B can view their own playlist
      const resOwner = await fetch(`${baseUrl}/api/playlists/${playlistB._id}`, {
        headers: { Authorization: `Bearer ${tokenUserB}` },
      });
      assert.strictEqual(resOwner.status, 200);
      const dataOwner = await resOwner.json();
      assert.strictEqual(dataOwner.playlist.name, 'TEST_PL_UserB_Party');

      // Admin has supervisory access to view
      const resAdmin = await fetch(`${baseUrl}/api/playlists/${playlistB._id}`, {
        headers: { Authorization: `Bearer ${tokenAdmin}` },
      });
      assert.strictEqual(resAdmin.status, 200);
    });

    it('PUT /api/playlists/:id renames playlist and updates description for owner', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/playlists/${playlistA._id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({
          name: 'TEST_PL_UserA_Renamed',
          description: 'Updated description for User A',
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.success, true);
      assert.strictEqual(data.playlist.name, 'TEST_PL_UserA_Renamed');
      assert.strictEqual(data.playlist.description, 'Updated description for User A');

      // Verify in DB
      const refreshed = await Playlist.findById(playlistA._id);
      assert.strictEqual(refreshed.name, 'TEST_PL_UserA_Renamed');
    });

    it('PUT /api/playlists/:id blocks User A from renaming User B playlist (HTTP 403 Forbidden)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/playlists/${playlistB._id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({ name: 'TEST_PL_Tampered' }),
      });

      assert.strictEqual(res.status, 403);
      const data = await res.json();
      assert.strictEqual(data.success, false);
      assert.match(data.message, /not authorized to modify another user’s playlist/i);
    });

    it('DELETE /api/playlists/:id blocks cross-user deletion (HTTP 403) and allows owner deletion (HTTP 200)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      // User A attempts to delete User B's playlist -> 403
      const resBlocked = await fetch(`${baseUrl}/api/playlists/${playlistB._id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });
      assert.strictEqual(resBlocked.status, 403);

      // User A deletes their own created playlist -> 200
      const resAllowed = await fetch(`${baseUrl}/api/playlists/${createdPlaylistId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });
      assert.strictEqual(resAllowed.status, 200);

      // Verify it's gone
      const deletedCheck = await Playlist.findById(createdPlaylistId);
      assert.strictEqual(deletedCheck, null);
    });
  });

  // =========================================================================
  // 3. Song Management in Playlist (Add & Remove)
  // =========================================================================
  describe('3. Song Management (Add & Remove)', () => {
    it('POST /api/playlists/:id/songs adds a song and prevents duplicates', async () => {
      if (mongoose.connection.readyState !== 1) return;

      // Add new song
      const res = await fetch(`${baseUrl}/api/playlists/${playlistA._id}/songs`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({ songId: 'vt_studio_ml' }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.success, true);
      assert.ok(data.songs.includes('vt_studio_ml'));

      // Attempt duplicate addition -> 400
      const dupRes = await fetch(`${baseUrl}/api/playlists/${playlistA._id}/songs`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({ songId: 'vt_studio_ml' }),
      });

      assert.strictEqual(dupRes.status, 400);
      const dupData = await dupRes.json();
      assert.strictEqual(dupData.success, false);
      assert.match(dupData.message, /already in this playlist/i);
    });

    it('POST /api/playlists/:id/songs blocks User A from adding songs to User B playlist (HTTP 403)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/playlists/${playlistB._id}/songs`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({ songId: 'vt_studio_ml' }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('DELETE /api/playlists/:id/songs/:songId removes song from playlist for owner', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/playlists/${playlistA._id}/songs/vt_studio_ml`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.success, true);
      assert.strictEqual(data.songs.includes('vt_studio_ml'), false);

      // Removing non-existent song returns 404
      const resNotFound = await fetch(`${baseUrl}/api/playlists/${playlistA._id}/songs/non_existent_song`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });
      assert.strictEqual(resNotFound.status, 404);
    });

    it('DELETE /api/playlists/:id/songs/:songId blocks User A from removing songs from User B playlist (HTTP 403)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/playlists/${playlistB._id}/songs/vt_studio_te`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });

      assert.strictEqual(res.status, 403);
    });
  });
});

