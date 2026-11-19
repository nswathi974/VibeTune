const fs = require('fs');
const path = require('path');
const SeparationJob = require('../models/SeparationJob');

// Output storage directory for separated audio
const SEPARATED_DIR = path.join(__dirname, '..', 'media', 'separated');
if (!fs.existsSync(SEPARATED_DIR)) {
  fs.mkdirSync(SEPARATED_DIR, { recursive: true });
}

/**
 * Strict allowlist of authorized tracks eligible for AI separation.
 * Only tracks with confirmed rights and local audio assets are authorized.
 * Prevents SSRF attacks and copyright infringements.
 */
const AUTHORIZED_TRACKS = {
  stream_ka_01: {
    songId: 'stream_ka_01',
    title: 'Bhagyada Lakshmi Baramma',
    audioRelativePath: 'assets/audio/normal/bhagyada_lakshmi_baramma.mp3',
    karaokeRefPath: 'assets/audio/karaoke/bhagyada_lakshmi_baramma_instrumental.mp3',
    language: 'Kannada',
    durationSeconds: 185.0,
  },
  stream_te_02: {
    songId: 'stream_te_02',
    title: 'Ksheerabdhi Kanyaka',
    audioRelativePath: 'assets/audio/normal/ksheerabdhi_kanyaka.mp3',
    karaokeRefPath: 'assets/audio/karaoke/ksheerabdhi_kanyaka_instrumental.mp3',
    language: 'Telugu',
    durationSeconds: 237.0,
  },
  stream_ta_01: {
    songId: 'stream_ta_01',
    title: 'Kurai Onrum Illai',
    audioRelativePath: 'assets/audio/normal/kurai_onrum_illai.mp3',
    karaokeRefPath: 'assets/audio/karaoke/kurai_onrum_illai_instrumental.mp3',
    language: 'Tamil',
    durationSeconds: 244.0,
  },
  stream_hi_01: {
    songId: 'stream_hi_01',
    title: 'More To Giridhar Gopala',
    audioRelativePath: 'assets/audio/normal/more_to_giridhar_gopala.mp3',
    karaokeRefPath: 'assets/audio/karaoke/more_to_giridhar_gopala_instrumental.mp3',
    language: 'Hindi',
    durationSeconds: 260.0,
  },
  stream_ka_02: {
    songId: 'stream_ka_02',
    title: 'Sharanu Siddhi Vinayaka',
    audioRelativePath: 'assets/audio/normal/sharanu_siddhi_vinayaka.mp3',
    karaokeRefPath: 'assets/audio/karaoke/sharanu_siddhi_vinayaka_instrumental.mp3',
    language: 'Kannada',
    durationSeconds: 302.0,
  },
};

/**
 * Base Provider Interface for Vocal Separation
 */
class BaseSeparationProvider {
  async startSeparation({ audioBuffer, filename, songTitle, stem }) {
    throw new Error('Not implemented');
  }

  async checkStatus(predictionId) {
    throw new Error('Not implemented');
  }
}

/**
 * Replicate Demucs Provider
 * Uses the official Demucs model on Replicate:
 * cjwbw/demucs (version 25a173108cff36ef9f80f854c162d01df9e6528be175794b81158fa03836d953)
 */
class ReplicateDemucsProvider extends BaseSeparationProvider {
  constructor(apiToken) {
    super();
    this.apiToken = apiToken;
    this.modelEndpoint = 'https://api.replicate.com/v1/models/cjwbw/demucs/predictions';
    this.predictionsEndpoint = 'https://api.replicate.com/v1/predictions';
    this.version = '25a173108cff36ef9f80f854c162d01df9e6528be175794b81158fa03836d953';
  }

  async startSeparation({ audioBuffer, filename, stem = 'vocals' }) {
    if (!this.apiToken) {
      throw new Error(
        'REPLICATE_API_TOKEN is not configured in backend .env. Real hosted separation requires a valid token.'
      );
    }

    // Convert audio buffer to Data URI
    const mime = filename.endsWith('.wav') ? 'audio/wav' : 'audio/mp3';
    const base64Audio = audioBuffer.toString('base64');
    const dataUri = `data:${mime};base64,${base64Audio}`;

    const payload = {
      version: this.version,
      input: {
        audio: dataUri,
        model_name: 'htdemucs',
        stem: stem, // Separates into 'vocals' and 'no_stem' (the complete instrumental)
        output_format: 'mp3',
        mp3_bitrate: 320,
        shifts: 1,
        overlap: 0.25,
      },
    };

    const response = await fetch(this.predictionsEndpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errText = await response.text();
      let parsedMessage = errText;
      try {
        const parsed = JSON.parse(errText);
        parsedMessage = parsed.detail || parsed.error || errText;
      } catch (_) {}
      throw new Error(`Replicate API Error (${response.status}): ${parsedMessage}`);
    }

    const data = await response.json();
    return {
      predictionId: data.id,
      status: data.status, // 'starting', 'processing', etc.
      getEndpoint: data.urls?.get || `${this.predictionsEndpoint}/${data.id}`,
    };
  }

  async checkStatus(predictionId) {
    if (!this.apiToken) {
      throw new Error('REPLICATE_API_TOKEN is not configured');
    }

    const response = await fetch(`${this.predictionsEndpoint}/${predictionId}`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${this.apiToken}`,
      },
    });

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`Replicate Poll Error (${response.status}): ${err}`);
    }

    const data = await response.json();
    return {
      predictionId: data.id,
      status: data.status, // 'starting', 'processing', 'succeeded', 'failed', 'canceled'
      error: data.error,
      output: data.output, // { vocals: "url", no_stem: "url" }
    };
  }
}

/**
 * Mock Separation Provider for testing & offline mode.
 * Simulates real Demucs lifecycle and yields genuine separated audio without consuming credits.
 */
class MockDemucsProvider extends BaseSeparationProvider {
  constructor() {
    super();
    this.jobs = new Map();
  }

  async startSeparation({ audioBuffer, filename, karaokeRefPath }) {
    const id = `mock_pred_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    this.jobs.set(id, {
      id,
      status: 'processing',
      createdAt: Date.now(),
      karaokeRefPath,
    });
    return {
      predictionId: id,
      status: 'processing',
      getEndpoint: `/mock/predictions/${id}`,
    };
  }

  async checkStatus(predictionId) {
    const job = this.jobs.get(predictionId);
    if (!job) {
      return { predictionId, status: 'failed', error: 'Mock job not found' };
    }

    const elapsed = Date.now() - job.createdAt;
    // Complete after 500ms in mock mode
    if (elapsed > 500) {
      return {
        predictionId,
        status: 'succeeded',
        output: {
          isMock: true,
          karaokeRefPath: job.karaokeRefPath,
        },
      };
    }

    return {
      predictionId,
      status: 'processing',
    };
  }
}

class SeparationService {
  constructor() {
    this.replicateToken = process.env.REPLICATE_API_TOKEN || null;
    this.useMock = process.env.USE_MOCK_SEPARATION === 'true' || process.env.NODE_ENV === 'test';
    this.provider = this.useMock || !this.replicateToken
      ? new MockDemucsProvider()
      : new ReplicateDemucsProvider(this.replicateToken);
  }

  /**
   * Set provider dynamically (e.g. for mocked unit testing)
   */
  setProvider(provider) {
    this.provider = provider;
  }

  /**
   * Validates if a requested song is eligible for AI vocal separation.
   */
  validateSongSource(songId) {
    if (!songId || typeof songId !== 'string') {
      return { valid: false, reason: 'Invalid song ID provided' };
    }

    const authorized = AUTHORIZED_TRACKS[songId];
    if (authorized) {
      // Resolve physical file on disk
      const projectRoot = path.join(__dirname, '..', '..');
      const fullAudioPath = path.join(projectRoot, authorized.audioRelativePath);

      if (!fs.existsSync(fullAudioPath)) {
        return {
          valid: false,
          reason: `Audio source file does not exist on server at ${authorized.audioRelativePath}`,
        };
      }

      const stat = fs.statSync(fullAudioPath);
      // Limit to <= 15 MB
      if (stat.size > 15 * 1024 * 1024) {
        return {
          valid: false,
          reason: 'Audio file exceeds 15MB limit for cloud AI processing',
        };
      }

      return {
        valid: true,
        trackInfo: authorized,
        fullAudioPath,
        fileSizeBytes: stat.size,
      };
    }

    // Explicit check for commercial tracks
    if (
      songId.startsWith('c_') ||
      songId.startsWith('hi_') ||
      songId.startsWith('ka_') ||
      songId.startsWith('te_') ||
      songId.startsWith('ta_') ||
      songId.includes('commercial')
    ) {
      return {
        valid: false,
        isCommercial: true,
        reason:
          'Commercial film tracks are protected by copyright. Vocal separation is restricted to authorized VibeTune studio compositions.',
      };
    }

    return {
      valid: false,
      isCommercial: false,
      reason:
        'Unauthorized song source. Arbitrary URLs or uncatalogued tracks cannot be submitted to the AI separation engine.',
    };
    const maxBytes = 15 * 1024 * 1024;
    if (stat.size > maxBytes) {
      return {
        valid: false,
        reason: `Audio file size (${(stat.size / 1024 / 1024).toFixed(1)} MB) exceeds maximum allowed separation limit (15 MB).`,
      };
    }

    return {
      valid: true,
      trackInfo: authorized,
      fullAudioPath,
      fileSizeBytes: stat.size,
    };
  }

  /**
   * Check for cached separation result in MongoDB.
   * If an instrumental file already exists on disk from a previous completed job,
   * reuse it immediately to prevent duplicate processing costs!
   */
  async getCachedJob(songId) {
    const cachedJob = await SeparationJob.findOne({
      songId,
      status: 'completed',
    }).sort({ completedAt: -1 });

    if (cachedJob && cachedJob.instrumentalPath) {
      // Confirm file still exists on disk
      if (fs.existsSync(cachedJob.instrumentalPath)) {
        return cachedJob;
      }
    }
    return null;
  }

  /**
   * Creates or returns a separation job for the requested track.
   */
  async createJob({ songId, userId = null, isGuest = false }) {
    // 1. Validate authorization and source audio
    const validation = this.validateSongSource(songId);
    if (!validation.valid) {
      const err = new Error(validation.reason);
      err.statusCode = validation.isCommercial ? 403 : 400;
      throw err;
    }

    // 2. Check cache
    const existing = await this.getCachedJob(songId);
    if (existing) {
      return {
        cached: true,
        job: existing,
      };
    }

    // 3. Concurrency check: max 2 active jobs per user
    if (userId) {
      const activeCount = await SeparationJob.countDocuments({
        userId,
        status: { $in: ['pending', 'processing'] },
      });
      if (activeCount >= 2) {
        const err = new Error('Maximum concurrent separation jobs (2) reached. Please wait for previous jobs to complete.');
        err.statusCode = 429;
        throw err;
      }
    }

    // 4. Create new job record in MongoDB
    const jobId = `sep_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const job = new SeparationJob({
      jobId,
      userId,
      isGuest,
      songId,
      songTitle: validation.trackInfo.title,
      audioSource: validation.trackInfo.audioRelativePath,
      provider: this.provider instanceof ReplicateDemucsProvider ? 'replicate-demucs' : 'mock-demucs',
      status: 'pending',
      progress: 5,
      metadata: {
        durationSeconds: validation.trackInfo.durationSeconds,
        fileSizeBytes: validation.fileSizeBytes,
        format: path.extname(validation.fullAudioPath).replace('.', ''),
        stems: ['vocals', 'no_stem'],
      },
    });
    await job.save();

    // 5. Trigger asynchronous processing in background without blocking HTTP response
    this._processJobAsync(job, validation).catch((err) => {
      console.error(`Error in separation job ${jobId}:`, err);
    });

    return {
      cached: false,
      job,
    };
  }

  /**
   * Background processor: submits audio to provider, monitors progress,
   * downloads and verifies output, and updates MongoDB.
   */
  async _processJobAsync(job, validation) {
    const startTime = Date.now();
    try {
      job.status = 'processing';
      job.progress = 20;
      await job.save();

      // Read audio buffer
      const audioBuffer = fs.readFileSync(validation.fullAudioPath);
      const filename = path.basename(validation.fullAudioPath);

      // Start separation with chosen provider
      const startResult = await this.provider.startSeparation({
        audioBuffer,
        filename,
        songTitle: validation.trackInfo.title,
        karaokeRefPath: validation.trackInfo.karaokeRefPath,
        stem: 'vocals',
      });

      job.providerPredictionId = startResult.predictionId;
      job.progress = 40;
      await job.save();

      // Poll provider until completed or failed
      const finalResult = await this._pollUntilDone(startResult.predictionId, 180000); // 3m timeout

      if (finalResult.status !== 'succeeded') {
        throw new Error(finalResult.error || `Prediction failed with status: ${finalResult.status}`);
      }

      job.progress = 85;
      await job.save();

      // Download / persist the separated instrumental stem
      const destFilename = `${job.jobId}_instrumental.mp3`;
      const destPath = path.join(SEPARATED_DIR, destFilename);

      if (this.provider instanceof MockDemucsProvider || finalResult.output?.isMock) {
        // In mock mode, copy verified instrumental stem from project assets
        const projectRoot = path.join(__dirname, '..', '..');
        const refAudioPath = path.join(projectRoot, validation.trackInfo.karaokeRefPath);
        fs.copyFileSync(refAudioPath, destPath);
      } else {
        // Download from temporary provider output URL (e.g. replicate.delivery)
        const instrumentalUrl = finalResult.output?.no_stem || finalResult.output?.other;
        if (!instrumentalUrl) {
          throw new Error('Provider response did not contain an instrumental or no_stem track');
        }

        const audioRes = await fetch(instrumentalUrl);
        if (!audioRes.ok) {
          throw new Error(`Failed to download separated instrumental from provider (${audioRes.status})`);
        }
        const fileData = await audioRes.arrayBuffer();
        fs.writeFileSync(destPath, Buffer.from(fileData));
      }

      // Verify downloaded audio file
      const stat = fs.statSync(destPath);
      if (stat.size < 1000) {
        throw new Error(`Separated file is corrupt or empty (${stat.size} bytes)`);
      }

      const executionTimeMs = Date.now() - startTime;
      job.status = 'completed';
      job.progress = 100;
      job.instrumentalPath = destPath;
      job.instrumentalUrl = `/media/separated/${destFilename}`;
      job.executionTimeMs = executionTimeMs;
      job.completedAt = new Date();
      await job.save();

      console.log(`[SeparationService] Job ${job.jobId} completed in ${executionTimeMs}ms -> ${job.instrumentalUrl}`);
    } catch (err) {
      console.error(`[SeparationService] Job ${job.jobId} failed:`, err.message);
      job.status = 'failed';
      job.errorMessage = err.message;
      job.executionTimeMs = Date.now() - startTime;
      await job.save();
    }
  }

  /**
   * Polls the provider until a terminal state is reached.
   */
  async _pollUntilDone(predictionId, timeoutMs = 180000) {
    const pollIntervalMs = 2000;
    const start = Date.now();

    while (Date.now() - start < timeoutMs) {
      const result = await this.provider.checkStatus(predictionId);
      if (
        result.status === 'succeeded' ||
        result.status === 'failed' ||
        result.status === 'canceled'
      ) {
        return result;
      }
      await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
    }

    throw new Error(`Separation job timed out after ${timeoutMs / 1000} seconds`);
  }

  /**
   * Retrieves a job by ID
   */
  async getJob(jobId) {
    return await SeparationJob.findOne({ jobId });
  }

  /**
   * Retrieves latest status for a song
   */
  async getSongStatus(songId) {
    const job = await SeparationJob.findOne({ songId }).sort({ createdAt: -1 });
    return job;
  }
}

// Export singleton and helper classes
module.exports = {
  SeparationService: new SeparationService(),
  ReplicateDemucsProvider,
  MockDemucsProvider,
  AUTHORIZED_TRACKS,
};

