const dns = require('dns');
// Ensure public DNS resolution for Atlas SRV queries across various Wi-Fi networks
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (_) {}

const mongoose = require('mongoose');

/**
 * Connect to MongoDB Atlas cluster using Mongoose.
 * Provides resilient reconnect logic and informative console logging.
 */
let retryTimer = null;

const connectDB = async () => {
  const uri = process.env.MONGODB_URI;

  if (!uri || uri.includes('<username>') || uri.includes('<password>')) {
    console.warn('\n============================================================');
    console.warn('⚠️  MONGODB_URI is not configured yet in backend/.env');
    console.warn('   Please open backend/.env and insert your MongoDB Atlas URI.');
    console.warn('   (The server will still run and serve /api/health)');
    console.warn('============================================================\n');
    return false;
  }

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: process.env.NODE_ENV === 'test' ? 5000 : 8000, // Resilient timeout for Atlas handshake in test mode
    });

    console.log(`\n✅ MongoDB Atlas Connected Successfully!`);
    console.log(`   Host:     ${conn.connection.host}`);
    console.log(`   Database: ${conn.connection.name}`);
    console.log(`   Status:   Ready for VibeTune user sessions\n`);

    // Ensure default demo accounts exist with appropriate roles
    try {
      const User = require('../models/User');
      const defaultUsers = [
        {
          name: 'Swathi MCA',
          email: 'swathi.mca@vibetune.com',
          password: 'vibetune2026',
          role: 'admin',
        },
        {
          name: 'Swathi',
          email: 'swathi@vibetune.com',
          password: 'vibetune123',
          role: 'user',
        },
      ];
      for (const userDef of defaultUsers) {
        const existing = await User.findOne({ email: userDef.email });
        if (!existing) {
          await User.create(userDef);
          console.log(`   🌱 Automatically seeded demo user: ${userDef.email} (${userDef.role})`);
        } else if (userDef.role && existing.role !== userDef.role) {
          existing.role = userDef.role;
          await existing.save();
        }
      }
    } catch (seedErr) {
      console.warn(`   ⚠️ Demo seeding warning: ${seedErr.message}`);
    }

    if (retryTimer) {
      clearInterval(retryTimer);
      retryTimer = null;
    }
    return true;
  } catch (error) {
    console.error(`\n❌ MongoDB Connection Error: ${error.message}`);
    console.error(`   Tip: Ensure your current IP is whitelisted in MongoDB Atlas Network Access.`);
    console.error(`   Tip: Recommended setting: 0.0.0.0/0 (Allow access from anywhere).`);

    if (!retryTimer && process.env.NODE_ENV !== 'test') {
      retryTimer = setInterval(() => {
        if (mongoose.connection.readyState === 0) {
          connectDB();
        }
      }, 5000);
      if (retryTimer.unref) retryTimer.unref();
    }
    return false;
  }
};

module.exports = connectDB;
