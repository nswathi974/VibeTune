const dns = require('dns');
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (_) { }

process.env.NODE_ENV = 'test';
require('dotenv').config();

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const User = require('../models/User');
const { protect, authorize, checkUserOwnership } = require('../middleware/auth');
const { app } = require('../server');

const TEST_SECRET = process.env.JWT_SECRET || 'vibetune_fallback_secret_key';

describe('VibeTune Authentication, Authorization & Security Tests', () => {
  let serverInstance;
  let baseUrl;
  let testUserA;
  let testUserB;
  let testAdminUser;
  let tokenUserA;
  let tokenUserB;
  let tokenAdmin;

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

    // 3. Clean up any leftover test users from prior runs
    if (mongoose.connection.readyState === 1) {
      await User.deleteMany({ email: /@authtest\.vibetune\.com$/i });

      // Create pre-seeded test fixtures
      testUserA = await User.create({
        name: 'Test Regular User A',
        email: 'user_a@authtest.vibetune.com',
        password: 'Password123!',
        role: 'user',
      });
      tokenUserA = jwt.sign({ id: testUserA._id }, TEST_SECRET, { expiresIn: '1h' });

      testUserB = await User.create({
        name: 'Test Regular User B',
        email: 'user_b@authtest.vibetune.com',
        password: 'Password123!',
        role: 'user',
      });
      tokenUserB = jwt.sign({ id: testUserB._id }, TEST_SECRET, { expiresIn: '1h' });

      testAdminUser = await User.create({
        name: 'Test Admin User',
        email: 'admin@authtest.vibetune.com',
        password: 'AdminPassword123!',
        role: 'admin',
      });
      tokenAdmin = jwt.sign({ id: testAdminUser._id }, TEST_SECRET, { expiresIn: '1h' });
    }
  });

  after(async () => {
    // Clean up test users and disconnect
    if (mongoose.connection.readyState === 1) {
      await User.deleteMany({ email: /@authtest\.vibetune\.com$/i });
    }
    await mongoose.disconnect();

    // Close ephemeral HTTP server
    if (serverInstance) {
      await new Promise((resolve) => serverInstance.close(resolve));
    }
  });

  // =========================================================================
  // SUITE 1: Password Hashing & Model Security
  // =========================================================================
  describe('1. Password Hashing & Data Sanitization', () => {
    it('Bcrypt automatically hashes passwords with salt factor 10 before saving', async () => {
      const rawPassword = 'PlainSecretPassword!2026';
      const user = new User({
        name: 'Crypt Test',
        email: 'crypt@authtest.vibetune.com',
        password: rawPassword,
      });

      // Before save hook runs, password is plain
      assert.strictEqual(user.password, rawPassword);

      if (mongoose.connection.readyState === 1) {
        await user.save();
        // After save, password must be bcrypt hash ($2a$ or $2b$)
        assert.notStrictEqual(user.password, rawPassword);
        assert.match(user.password, /^\$2[ab]\$10\$/);

        // Verify matchPassword succeeds with plain password
        const isMatch = await user.matchPassword(rawPassword);
        assert.strictEqual(isMatch, true);

        // Verify matchPassword rejects wrong password
        const wrongMatch = await user.matchPassword('IncorrectPassword');
        assert.strictEqual(wrongMatch, false);

        await User.deleteOne({ _id: user._id });
      }
    });

    it('toJSON() sanitization strictly removes password and __v from output', () => {
      const user = new User({
        name: 'Sanitize Test',
        email: 'sanitize@authtest.vibetune.com',
        password: 'SecretPassword123',
        role: 'user',
      });

      const jsonOutput = user.toJSON();
      assert.strictEqual(jsonOutput.password, undefined);
      assert.strictEqual(jsonOutput.__v, undefined);
      assert.strictEqual(jsonOutput.name, 'Sanitize Test');
      assert.strictEqual(jsonOutput.role, 'user');
    });

    it('User role defaults to "user" and rejects invalid role values', () => {
      const defaultUser = new User({
        name: 'Default Role',
        email: 'default@authtest.vibetune.com',
        password: 'Password123',
      });
      assert.strictEqual(defaultUser.role, 'user');

      const invalidRoleUser = new User({
        name: 'Invalid Role',
        email: 'invalid@authtest.vibetune.com',
        password: 'Password123',
        role: 'super_hacker',
      });
      const validationError = invalidRoleUser.validateSync();
      assert.ok(validationError);
      assert.ok(validationError.errors.role);
    });
  });

  // =========================================================================
  // SUITE 2: Middleware Authentication & Token Validation
  // =========================================================================
  describe('2. Authentication Middleware (protect)', () => {
    it('Rejects requests with missing Authorization header (HTTP 401)', async () => {
      let statusCalled = null;
      let jsonCalled = null;
      const req = { headers: {} };
      const res = {
        status: (code) => {
          statusCalled = code;
          return {
            json: (payload) => {
              jsonCalled = payload;
            },
          };
        },
      };

      await protect(req, res, () => { });
      assert.strictEqual(statusCalled, 401);
      assert.strictEqual(jsonCalled.success, false);
      assert.match(jsonCalled.message, /no token provided/i);
    });

    it('Rejects requests with malformed token (HTTP 401)', async () => {
      let statusCalled = null;
      let jsonCalled = null;
      const req = { headers: { authorization: 'Bearer invalid.tampered.token' } };
      const res = {
        status: (code) => {
          statusCalled = code;
          return {
            json: (payload) => {
              jsonCalled = payload;
            },
          };
        },
      };

      await protect(req, res, () => { });
      assert.strictEqual(statusCalled, 401);
      assert.strictEqual(jsonCalled.success, false);
      assert.match(jsonCalled.message, /invalid or expired/i);
    });

    it('Rejects expired tokens with specific expiration notice (HTTP 401)', async () => {
      const expiredToken = jwt.sign({ id: 'dummy_user_id' }, TEST_SECRET, {
        expiresIn: '-10s', // Expired 10 seconds ago
      });

      let statusCalled = null;
      let jsonCalled = null;
      const req = { headers: { authorization: `Bearer ${expiredToken}` } };
      const res = {
        status: (code) => {
          statusCalled = code;
          return {
            json: (payload) => {
              jsonCalled = payload;
            },
          };
        },
      };

      await protect(req, res, () => { });
      assert.strictEqual(statusCalled, 401);
      assert.strictEqual(jsonCalled.success, false);
      assert.match(jsonCalled.message, /token has expired/i);
    });
  });

  // =========================================================================
  // SUITE 3: Role-Based Authorization & Ownership Middleware
  // =========================================================================
  describe('3. Role Authorization & User Ownership Checks', () => {
    it('authorize("admin") blocks regular user (HTTP 403 Forbidden)', () => {
      let statusCalled = null;
      let jsonCalled = null;
      const req = { user: { role: 'user' } };
      const res = {
        status: (code) => {
          statusCalled = code;
          return {
            json: (payload) => {
              jsonCalled = payload;
            },
          };
        },
      };

      const adminGuard = authorize('admin');
      adminGuard(req, res, () => { });

      assert.strictEqual(statusCalled, 403);
      assert.strictEqual(jsonCalled.success, false);
      assert.match(jsonCalled.message, /not authorized/i);
    });

    it('authorize("admin") permits admin user to proceed', () => {
      let nextCalled = false;
      const req = { user: { role: 'admin' } };
      const res = {};

      const adminGuard = authorize('admin');
      adminGuard(req, res, () => {
        nextCalled = true;
      });

      assert.strictEqual(nextCalled, true);
    });

    it('checkUserOwnership blocks User A from accessing User B resources (HTTP 403)', () => {
      let statusCalled = null;
      let jsonCalled = null;
      const req = {
        user: { _id: '64a000000000000000000001', role: 'user' },
        params: { userId: '64b000000000000000000002' },
      };
      const res = {
        status: (code) => {
          statusCalled = code;
          return {
            json: (payload) => {
              jsonCalled = payload;
            },
          };
        },
      };

      const ownershipGuard = checkUserOwnership('userId');
      ownershipGuard(req, res, () => { });

      assert.strictEqual(statusCalled, 403);
      assert.strictEqual(jsonCalled.success, false);
      assert.match(jsonCalled.message, /not authorized to view or modify another user's resources/i);
    });

    it('checkUserOwnership permits resource owner to proceed', () => {
      let nextCalled = false;
      const ownerId = '64a000000000000000000001';
      const req = {
        user: { _id: ownerId, role: 'user' },
        params: { userId: ownerId },
      };
      const res = {};

      const ownershipGuard = checkUserOwnership('userId');
      ownershipGuard(req, res, () => {
        nextCalled = true;
      });

      assert.strictEqual(nextCalled, true);
    });

    it('checkUserOwnership permits Admin supervisory override on any user resource', () => {
      let nextCalled = false;
      const req = {
        user: { _id: 'admin_id_001', role: 'admin' },
        params: { userId: 'any_other_user_id_002' },
      };
      const res = {};

      const ownershipGuard = checkUserOwnership('userId');
      ownershipGuard(req, res, () => {
        nextCalled = true;
      });

      assert.strictEqual(nextCalled, true);
    });
  });

  // =========================================================================
  // SUITE 4: Live HTTP API Endpoints (/api/auth)
  // =========================================================================
  describe('4. Full HTTP Endpoint Security & Integrity', () => {
    it('POST /api/auth/signup strictly ignores role escalation attempts (creates role="user")', async () => {
      if (mongoose.connection.readyState !== 1) {
        console.log('Skipping live DB HTTP test (MongoDB not connected)');
        return;
      }

      const res = await fetch(`${baseUrl}/api/auth/signup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Hacker Attempt',
          email: 'escalation_test@authtest.vibetune.com',
          password: 'SecretPassword123!',
          role: 'admin', // Malicious attempt to self-assign admin
        }),
      });

      const data = await res.json();
      assert.strictEqual(res.status, 201);
      assert.strictEqual(data.success, true);
      assert.ok(data.token, 'Must return JWT token');
      assert.strictEqual(data.user.role, 'user', 'Role must remain "user" despite payload');
      assert.strictEqual(data.user.password, undefined, 'Password must never be returned');

      // Double-check database record directly
      const savedUser = await User.findById(data.user.id);
      assert.strictEqual(savedUser.role, 'user');
    });

    it('POST /api/auth/signup rejects duplicate email registration (HTTP 400)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/auth/signup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Duplicate Attempt',
          email: 'user_a@authtest.vibetune.com', // Already registered in before()
          password: 'Password123!',
        }),
      });

      const data = await res.json();
      assert.strictEqual(res.status, 400);
      assert.strictEqual(data.success, false);
      assert.match(data.message, /already registered/i);
    });

    it('POST /api/auth/signup rejects invalid inputs (missing fields, short password, invalid email)', async () => {
      // Missing name
      const res1 = await fetch(`${baseUrl}/api/auth/signup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'valid@authtest.vibetune.com',
          password: 'Password123!',
        }),
      });
      assert.strictEqual(res1.status, 400);

      // Short password (<6 chars)
      const res2 = await fetch(`${baseUrl}/api/auth/signup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Valid Name',
          email: 'valid2@authtest.vibetune.com',
          password: '123',
        }),
      });
      assert.strictEqual(res2.status, 400);

      // Invalid email format
      const res3 = await fetch(`${baseUrl}/api/auth/signup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Valid Name',
          email: 'not-an-email',
          password: 'Password123!',
        }),
      });
      assert.strictEqual(res3.status, 400);
    });

    it('POST /api/auth/login authenticates valid credentials and returns JWT', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'user_a@authtest.vibetune.com',
          password: 'Password123!',
        }),
      });

      const data = await res.json();
      assert.strictEqual(res.status, 200);
      assert.strictEqual(data.success, true);
      assert.ok(data.token);
      assert.strictEqual(data.user.email, 'user_a@authtest.vibetune.com');
      assert.strictEqual(data.user.role, 'user');
    });

    it('POST /api/auth/login rejects invalid password (HTTP 401)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'user_a@authtest.vibetune.com',
          password: 'WrongPassword123!',
        }),
      });

      const data = await res.json();
      assert.strictEqual(res.status, 401);
      assert.strictEqual(data.success, false);
      assert.match(data.message, /invalid email or password/i);
    });

    it('POST /api/auth/login rejects non-existent email (HTTP 401)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'nonexistent_user@authtest.vibetune.com',
          password: 'Password123!',
        }),
      });

      const data = await res.json();
      assert.strictEqual(res.status, 401);
      assert.strictEqual(data.success, false);
      assert.match(data.message, /invalid email or password/i);
    });

    it('POST /api/auth/logout succeeds with 200 OK', async () => {
      const res = await fetch(`${baseUrl}/api/auth/logout`, {
        method: 'POST',
      });
      const data = await res.json();
      assert.strictEqual(res.status, 200);
      assert.strictEqual(data.success, true);
    });

    it('GET /api/auth/me returns authenticated user profile', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/auth/me`, {
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });

      const data = await res.json();
      assert.strictEqual(res.status, 200);
      assert.strictEqual(data.success, true);
      assert.strictEqual(data.user.email, 'user_a@authtest.vibetune.com');
      assert.strictEqual(data.user.role, 'user');
    });

    it('PUT /api/auth/profile blocks role modification by user', async () => {
      if (mongoose.connection.readyState !== 1) return;

      const res = await fetch(`${baseUrl}/api/auth/profile`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({
          name: 'Updated Name A',
          role: 'admin', // Tamper attempt
        }),
      });

      const data = await res.json();
      assert.strictEqual(res.status, 200);
      assert.strictEqual(data.user.name, 'Updated Name A');
      assert.strictEqual(data.user.role, 'user', 'Role must remain "user"');

      // Verify directly from database
      const refreshed = await User.findById(testUserA._id);
      assert.strictEqual(refreshed.role, 'user');
    });

    it('GET /api/auth/user/:userId/data enforces ownership (blocks User A from User B, permits Owner)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      // 1. User A tries to access User B's data -> 403 Forbidden
      const resForbidden = await fetch(`${baseUrl}/api/auth/user/${testUserB._id}/data`, {
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });
      assert.strictEqual(resForbidden.status, 403);
      const dataForbidden = await resForbidden.json();
      assert.strictEqual(dataForbidden.success, false);

      // 2. User A accesses own data -> 200 OK
      const resAllowed = await fetch(`${baseUrl}/api/auth/user/${testUserA._id}/data`, {
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });
      assert.strictEqual(resAllowed.status, 200);
      const dataAllowed = await resAllowed.json();
      assert.strictEqual(dataAllowed.success, true);
      assert.strictEqual(dataAllowed.data.userId.toString(), testUserA._id.toString());

      // 3. Admin accesses User B's data -> 200 OK (Supervisory override)
      const resAdmin = await fetch(`${baseUrl}/api/auth/user/${testUserB._id}/data`, {
        headers: { Authorization: `Bearer ${tokenAdmin}` },
      });
      assert.strictEqual(resAdmin.status, 200);
      const dataAdmin = await resAdmin.json();
      assert.strictEqual(dataAdmin.success, true);
      assert.strictEqual(dataAdmin.data.requesterRole, 'admin');
    });

    it('GET /api/auth/admin/users blocks regular user (403) and allows admin (200)', async () => {
      if (mongoose.connection.readyState !== 1) return;

      // Regular user blocked
      const userRes = await fetch(`${baseUrl}/api/auth/admin/users`, {
        headers: { Authorization: `Bearer ${tokenUserA}` },
      });
      assert.strictEqual(userRes.status, 403);

      // Admin user allowed
      const adminRes = await fetch(`${baseUrl}/api/auth/admin/users`, {
        headers: { Authorization: `Bearer ${tokenAdmin}` },
      });
      assert.strictEqual(adminRes.status, 200);
      const adminData = await adminRes.json();
      assert.strictEqual(adminData.success, true);
      assert.ok(Array.isArray(adminData.users));
      assert.ok(adminData.count >= 2);
    });

    it('PUT /api/auth/admin/users/:id/role permits admin to manage user roles and rejects invalid roles', async () => {
      if (mongoose.connection.readyState !== 1) return;

      // Regular user blocked from updating role
      const unauthRes = await fetch(`${baseUrl}/api/auth/admin/users/${testUserB._id}/role`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenUserA}`,
        },
        body: JSON.stringify({ role: 'admin' }),
      });
      assert.strictEqual(unauthRes.status, 403);

      // Admin updates User B to 'admin'
      const authRes = await fetch(`${baseUrl}/api/auth/admin/users/${testUserB._id}/role`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenAdmin}`,
        },
        body: JSON.stringify({ role: 'admin' }),
      });
      assert.strictEqual(authRes.status, 200);
      const authData = await authRes.json();
      assert.strictEqual(authData.user.role, 'admin');

      // Admin attempts invalid role -> 400
      const invalidRes = await fetch(`${baseUrl}/api/auth/admin/users/${testUserB._id}/role`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenAdmin}`,
        },
        body: JSON.stringify({ role: 'superuser' }),
      });
      assert.strictEqual(invalidRes.status, 400);

      // Revert User B back to 'user'
      await fetch(`${baseUrl}/api/auth/admin/users/${testUserB._id}/role`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenAdmin}`,
        },
        body: JSON.stringify({ role: 'user' }),
      });
    });
  });
});