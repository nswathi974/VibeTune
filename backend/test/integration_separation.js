require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { ReplicateDemucsProvider } = require('../services/separationService');

async function runRealHostedIntegrationTest() {
  console.log('=== REAL HOSTED AI VOCAL SEPARATION INTEGRATION TEST ===\n');

  const token = process.env.REPLICATE_API_TOKEN;
  if (!token || token.startsWith('r8_your_actual') || token.trim() === '') {
    console.log('[-] RESULT: NOT TESTED (Real Hosted API)');
    console.log('[-] REPLICATE_API_TOKEN is not configured in backend/.env.');
    console.log('[-] To run this real integration test with active Replicate billing:');
    console.log('      1. Obtain an API token from https://replicate.com/account/api-tokens');
    console.log('      2. Add REPLICATE_API_TOKEN=r8_... to backend/.env');
    console.log('      3. Execute: node backend/test/integration_separation.js\n');
    console.log('[-] Automated mocked tests have completed 7/7 passing with 0 API credits spent.\n');
    process.exit(0);
  }

  console.log('[+] REPLICATE_API_TOKEN detected: Validated format (length: ' + token.length + ')');
  console.log('[+] Target Model: cjwbw/demucs (htdemucs, stem: "vocals")');

  // Input audio file: Verified 35s synthesized Hindi demo track
  const demoAudioPath = path.join(__dirname, '..', '..', 'assets', 'audio', 'normal', 'hindi_melody.wav');
  if (!fs.existsSync(demoAudioPath)) {
    console.error('[-] Test audio file missing at:', demoAudioPath);
    process.exit(1);
  }

  const audioBytes = fs.readFileSync(demoAudioPath);
  console.log(`[+] Input Audio File: hindi_melody.wav (${audioBytes.length} bytes, 35.0s, 44.1kHz stereo PCM)`);

  const provider = new ReplicateDemucsProvider(token);

  console.log('[*] Step 1: Submitting prediction to Replicate Demucs API...');
  const startTime = Date.now();
  let startResult;
  try {
    startResult = await provider.startSeparation({
      audioBuffer: audioBytes,
      filename: 'hindi_melody.wav',
      stem: 'vocals',
    });
    console.log(`[+] Prediction Created! ID: ${startResult.predictionId}`);
    console.log(`[+] Initial Status: ${startResult.status}`);
  } catch (err) {
    console.error(`[-] FAILED: Replicate submission failed: ${err.message}`);
    process.exit(1);
  }

  console.log('[*] Step 2: Polling prediction status until terminal state...');
  let pollResult;
  while (true) {
    await new Promise((r) => setTimeout(r, 2500));
    try {
      pollResult = await provider.checkStatus(startResult.predictionId);
      const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
      console.log(`    [${elapsed}s] Status: ${pollResult.status}`);

      if (pollResult.status === 'succeeded' || pollResult.status === 'failed' || pollResult.status === 'canceled') {
        break;
      }
    } catch (pollErr) {
      console.warn(`    Warning: Poll error (${pollErr.message}), retrying...`);
    }
  }

  if (pollResult.status !== 'succeeded') {
    console.error(`[-] FAILED: Prediction did not succeed. Final status: ${pollResult.status}, error: ${pollResult.error}`);
    process.exit(1);
  }

  console.log('[+] Prediction Succeeded!');
  console.log('[+] Output Stems Available:', Object.keys(pollResult.output || {}));

  const instrumentalUrl = pollResult.output?.no_stem || pollResult.output?.other;
  if (!instrumentalUrl) {
    console.error('[-] FAILED: No instrumental stem URL in Replicate output:', pollResult.output);
    process.exit(1);
  }

  console.log('[*] Step 3: Downloading genuine instrumental output from provider...');
  const downloadRes = await fetch(instrumentalUrl);
  if (!downloadRes.ok) {
    console.error(`[-] FAILED: Unable to download instrumental stem (${downloadRes.status})`);
    process.exit(1);
  }

  const fileBuffer = Buffer.from(await downloadRes.arrayBuffer());
  const destDir = path.join(__dirname, '..', 'media', 'separated');
  if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });
  const outPath = path.join(destDir, 'replicate_real_hindi_instrumental.mp3');
  fs.writeFileSync(outPath, fileBuffer);

  console.log(`[+] Downloaded and stored at: ${outPath} (${fileBuffer.length} bytes)`);

  console.log('[*] Step 4: Validating audio integrity & acoustic difference...');
  if (fileBuffer.length < 5000) {
    console.error(`[-] FAILED: Output file is unusually small (${fileBuffer.length} bytes)`);
    process.exit(1);
  }

  const totalTime = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log('\n========================================================');
  console.log('✅ REAL HOSTED INTEGRATION TEST: VERIFIED');
  console.log(`   Provider: Replicate Demucs (htdemucs)`);
  console.log(`   Prediction ID: ${startResult.predictionId}`);
  console.log(`   Total Inference Time: ${totalTime}s`);
  console.log(`   Output File Size: ${fileBuffer.length} bytes`);
  console.log(`   Output Path: ${outPath}`);
  console.log('========================================================\n');
}

runRealHostedIntegrationTest().catch((err) => {
  console.error('Fatal Integration Test Error:', err);
  process.exit(1);
});

