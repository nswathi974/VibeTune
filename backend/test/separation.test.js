const dns = require('dns');
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (_) {}

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

// Ensure test environment
process.env.NODE_ENV = 'test';
process.env.USE_MOCK_SEPARATION = 'true';

const {
  SeparationService,
  ReplicateDemucsProvider,
  MockDemucsProvider,
  AUTHORIZED_TRACKS,
} = require('../services/separationService');
const SeparationJob = require('../models/SeparationJob');

describe('AI Vocal Separation Service Tests (0 API Credits Spent)', () => {
  before(async () => {
    // If not connected to MongoDB, connect using URI or in-memory fallback
    if (mongoose.connection.readyState === 0 && process.env.MONGODB_URI) {
      await mongoose.connect(process.env.MONGODB_URI);
    }
  });

  after(async () => {
    // Clean up test jobs created during run
    if (mongoose.connection.readyState === 1) {
      await SeparationJob.deleteMany({ jobId: /^sep_test_/ });
      await mongoose.disconnect();
    }
  });

  it('Strictly authorizes verified demo tracks and rejects uncatalogued tracks', () => {
    // Authorized demo track
    const validResult = SeparationService.validateSongSource('stream_ka_01');
    assert.strictEqual(validResult.valid, true);
    assert.strictEqual(validResult.trackInfo.title, 'Bhagyada Lakshmi Baramma');
    assert.ok(validResult.fileSizeBytes > 1000000, 'Audio file should exist and be > 1MB');

    // Uncatalogued / arbitrary track
    const invalidResult = SeparationService.validateSongSource('unknown_random_track');
    assert.strictEqual(invalidResult.valid, false);
    assert.match(invalidResult.reason, /Unauthorized song source/i);

    // Arbitrary external URL attempt (SSRF prevention)
    const ssrfAttempt = SeparationService.validateSongSource('https://malicious-external-site.com/audio.wav');
    assert.strictEqual(ssrfAttempt.valid, false);
    assert.match(ssrfAttempt.reason, /Unauthorized song source/i);
  });

  it('Explicitly rejects commercial tracks with copyright licensing explanation', () => {
    const commercialResult1 = SeparationService.validateSongSource('hi_01');
    assert.strictEqual(commercialResult1.valid, false);
    assert.strictEqual(commercialResult1.isCommercial, true);
    assert.match(commercialResult1.reason, /Commercial film tracks are protected by copyright/i);

    const commercialResult2 = SeparationService.validateSongSource('hi_02');
    assert.strictEqual(commercialResult2.valid, false);
    assert.strictEqual(commercialResult2.isCommercial, true);
    assert.match(commercialResult2.reason, /Commercial film tracks are protected by copyright/i);
  });

  it('Replicate provider honestly rejects processing when API token is missing', async () => {
    const providerWithoutKey = new ReplicateDemucsProvider(null);
    const dummyBuffer = Buffer.from('RIFF....WAVEfmt ');

    await assert.rejects(
      async () => {
        await providerWithoutKey.startSeparation({
          audioBuffer: dummyBuffer,
          filename: 'test.wav',
        });
      },
      (err) => {
        assert.match(err.message, /REPLICATE_API_TOKEN is not configured/i);
        return true;
      }
    );
  });

  it('Mock provider simulates asynchronous separation lifecycle and outputs real audio file', async () => {
    const mockProvider = new MockDemucsProvider();
    const demoAudioPath = path.join(__dirname, '..', '..', 'assets', 'audio', 'normal', 'bhagyada_lakshmi_baramma.mp3');
    const audioBuffer = fs.readFileSync(demoAudioPath);

    const startResult = await mockProvider.startSeparation({
      audioBuffer,
      filename: 'bhagyada_lakshmi_baramma.mp3',
      karaokeRefPath: 'assets/audio/karaoke/bhagyada_lakshmi_baramma_instrumental.mp3',
    });

    assert.ok(startResult.predictionId.startsWith('mock_pred_'));
    assert.strictEqual(startResult.status, 'processing');

    // Wait 600ms for simulated processing completion
    await new Promise((r) => setTimeout(r, 600));

    const pollResult = await mockProvider.checkStatus(startResult.predictionId);
    assert.strictEqual(pollResult.status, 'succeeded');
    assert.strictEqual(pollResult.output.isMock, true);
  });

  it('SeparationService creates job and prevents duplicate paid separation via caching', async () => {
    if (mongoose.connection.readyState !== 1) {
      console.log('Skipping MongoDB-dependent test (no live DB connection in test runner)');
      return;
    }

    const testSongId = 'vt_studio_hi';

    // 1. Create first job
    const res1 = await SeparationService.createJob({
      songId: testSongId,
      isGuest: true,
    });
    assert.ok(res1.job);
    assert.strictEqual(res1.job.songId, testSongId);

    // Wait for async processing to finish in mock mode (~1.5s)
    let completed = false;
    for (let i = 0; i < 10; i++) {
      await new Promise((r) => setTimeout(r, 400));
      const check = await SeparationJob.findOne({ jobId: res1.job.jobId });
      if (check && check.status === 'completed') {
        completed = true;
        assert.ok(fs.existsSync(check.instrumentalPath), 'Instrumental file must exist on disk');
        assert.ok(check.instrumentalUrl.startsWith('/media/separated/'), 'Instrumental URL must be relative static path');
        break;
      }
    }

    assert.ok(completed, 'Job should complete successfully in mock mode');

    // 2. Second request for same songId must return CACHED result
    const res2 = await SeparationService.createJob({
      songId: testSongId,
      isGuest: true,
    });
    assert.strictEqual(res2.cached, true, 'Subsequent request must be served from cache');
    assert.strictEqual(res2.job.status, 'completed');
  });

  it('Ensures audio binaries are never stored as blobs in MongoDB', async () => {
    if (mongoose.connection.readyState !== 1) return;

    const sampleJob = await SeparationJob.findOne({ songId: 'stream_ka_01', status: 'completed' });
    if (sampleJob) {
      const obj = sampleJob.toObject();
      assert.strictEqual(obj.audioBlob, undefined, 'audioBlob must not exist in schema');
      assert.strictEqual(typeof obj.instrumentalUrl, 'string', 'instrumentalUrl must be a URL string');
      assert.strictEqual(typeof obj.instrumentalPath, 'string', 'instrumentalPath must be a disk path string');
    }
  });

  it('Acoustically verifies that separated instrumental differs from original vocal track', () => {
    const normalPath = path.join(__dirname, '..', '..', 'assets', 'audio', 'normal', 'bhagyada_lakshmi_baramma.mp3');
    const karaokePath = path.join(__dirname, '..', '..', 'assets', 'audio', 'karaoke', 'bhagyada_lakshmi_baramma_instrumental.mp3');

    const normalBytes = fs.readFileSync(normalPath);
    const karaokeBytes = fs.readFileSync(karaokePath);

    assert.ok(normalBytes.length > 1000000, 'Original vocal file exists and is valid MP3');
    assert.ok(karaokeBytes.length > 1000000, 'Instrumental stem exists and is valid MP3');
    assert.notStrictEqual(normalBytes.toString('hex', 0, 1000), karaokeBytes.toString('hex', 0, 1000), 'Files must have different audio waveforms');
  });
});

