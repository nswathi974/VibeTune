import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  print('Synthesizing high-quality demo audio files for VibeTune...');

  final sampleRate = 44100;
  final durationSeconds = 35.0; // 35 seconds per track
  final totalSamples = (sampleRate * durationSeconds).toInt();

  // Create directories if not exist
  Directory('assets/audio/normal').createSync(recursive: true);
  Directory('assets/audio/karaoke').createSync(recursive: true);
  Directory('assets/lyrics').createSync(recursive: true);

  // 1. Hindi Romantic Melody (Key of C, 115 BPM)
  generateTrackPair(
    name: 'hindi_melody',
    sampleRate: sampleRate,
    totalSamples: totalSamples,
    bpm: 115,
    chordProgression: [
      [261.63, 329.63, 392.00], // C major
      [220.00, 261.63, 329.63], // A minor
      [174.61, 220.00, 261.63], // F major
      [196.00, 246.94, 293.66], // G major
    ],
    melodyScale: [261.63, 293.66, 329.63, 392.00, 440.00, 523.25], // C major pentatonic
  );

  // 2. Kannada Sandalwood Melody (Key of D, 110 BPM)
  generateTrackPair(
    name: 'kannada_melody',
    sampleRate: sampleRate,
    totalSamples: totalSamples,
    bpm: 110,
    chordProgression: [
      [293.66, 369.99, 440.00], // D major
      [246.94, 293.66, 369.99], // B minor
      [196.00, 246.94, 293.66], // G major
      [220.00, 277.18, 329.63], // A major
    ],
    melodyScale: [293.66, 329.63, 369.99, 440.00, 493.88, 587.33], // D major pentatonic
  );

  // 3. Telugu Tollywood Beat (Key of E minor, 126 BPM)
  generateTrackPair(
    name: 'telugu_melody',
    sampleRate: sampleRate,
    totalSamples: totalSamples,
    bpm: 126,
    chordProgression: [
      [164.81, 196.00, 246.94], // Em
      [261.63, 329.63, 392.00], // C
      [196.00, 246.94, 293.66], // G
      [293.66, 369.99, 440.00], // D
    ],
    melodyScale: [329.63, 369.99, 392.00, 440.00, 493.88, 587.33], // E minor pentatonic
  );

  // 4. Tamil Kollywood Acoustic (Key of A, 112 BPM)
  generateTrackPair(
    name: 'tamil_melody',
    sampleRate: sampleRate,
    totalSamples: totalSamples,
    bpm: 112,
    chordProgression: [
      [220.00, 277.18, 329.63], // A major
      [185.00, 220.00, 277.18], // F#m
      [196.00, 246.94, 293.66], // G (modal feel)
      [246.94, 311.13, 369.99], // Bm
    ],
    melodyScale: [220.00, 246.94, 277.18, 329.63, 369.99, 440.00],
  );

  // 5. Malayalam Mollywood Serene (Key of F, 96 BPM)
  generateTrackPair(
    name: 'malayalam_melody',
    sampleRate: sampleRate,
    totalSamples: totalSamples,
    bpm: 96,
    chordProgression: [
      [174.61, 220.00, 261.63], // F major
      [220.00, 261.63, 329.63], // Am
      [146.83, 174.61, 220.00], // Dm
      [233.08, 293.66, 349.23], // Bb
    ],
    melodyScale: [261.63, 293.66, 329.63, 349.23, 392.00, 440.00],
  );

  print('Audio generation complete! All tracks generated successfully.');
}

void generateTrackPair({
  required String name,
  required int sampleRate,
  required int totalSamples,
  required double bpm,
  required List<List<double>> chordProgression,
  required List<double> melodyScale,
}) {
  final samplesPerBeat = (sampleRate * 60.0 / bpm).toInt();
  final beatsPerChord = 4;
  final samplesPerChord = samplesPerBeat * beatsPerChord;

  // Buffers for Stereo 16-bit PCM
  final normalBuffer = Int16List(totalSamples * 2);
  final karaokeBuffer = Int16List(totalSamples * 2);

  // Pseudo-random melody generator based on melodyScale and chord progression
  final rng = Random(name.hashCode);
  final melodyNotes = <double>[];
  final totalBeats = (totalSamples / samplesPerBeat).ceil();
  for (int b = 0; b < totalBeats; b++) {
    // 2 melody notes per beat (8th notes)
    final chordIdx = (b ~/ beatsPerChord) % chordProgression.length;
    final currentChord = chordProgression[chordIdx];
    // 70% chance chord tone, 30% scale tone
    if (rng.nextDouble() < 0.7) {
      melodyNotes.add(currentChord[rng.nextInt(currentChord.length)] * 2); // octave up
    } else {
      melodyNotes.add(melodyScale[rng.nextInt(melodyScale.length)]);
    }
  }

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final beatIndex = (i / samplesPerBeat).floor();
    final chordIndex = (i / samplesPerChord).floor() % chordProgression.length;
    final chord = chordProgression[chordIndex];

    // 1. Harmonies / Chords Pad (Gentle warm strings/pad)
    double chordSignal = 0.0;
    for (final freq in chord) {
      // Sine wave with subtle rich harmonics
      chordSignal += 0.08 * sin(2 * pi * freq * t);
      chordSignal += 0.04 * sin(2 * pi * freq * 2 * t);
    }

    // 2. Bassline (Smooth acoustic bass on beat)
    final bassFreq = chord[0] / 2.0;
    final beatProgress = (i % samplesPerBeat) / samplesPerBeat;
    final bassEnvelope = exp(-beatProgress * 3.5);
    final bassSignal = 0.18 * sin(2 * pi * bassFreq * t) * bassEnvelope;

    // 3. Rhythm Percussion (Acoustic kick & soft hi-hat / shaker)
    double rhythmSignal = 0.0;
    final isKick = (beatIndex % 2 == 0);
    if (isKick) {
      final kickEnv = exp(-beatProgress * 12.0);
      final kickPitch = 60.0 + 80.0 * exp(-beatProgress * 25.0);
      rhythmSignal += 0.22 * sin(2 * pi * kickPitch * t) * kickEnv;
    } else {
      // Snare / rimshot feel
      final snareEnv = exp(-beatProgress * 10.0);
      final snareNoise = (rng.nextDouble() * 2.0 - 1.0) * 0.09 * snareEnv;
      rhythmSignal += snareNoise;
    }
    // Hi-hat / Shaker tick every half beat
    final halfBeatProgress = (i % (samplesPerBeat ~/ 2)) / (samplesPerBeat ~/ 2);
    final hatEnv = exp(-halfBeatProgress * 18.0);
    rhythmSignal += (rng.nextDouble() * 2.0 - 1.0) * 0.04 * hatEnv;

    // Combined Instrumental / Karaoke Backing Track
    final backingMono = (chordSignal + bassSignal + rhythmSignal);

    // 4. Vocal / Lead Melody (Flute / Synthesizer with soft vibrato)
    final subBeat = (i * 2 ~/ samplesPerBeat);
    final noteIdx = subBeat % melodyNotes.length;
    final currentNote = melodyNotes[noteIdx];
    final noteProgress = ((i * 2) % samplesPerBeat) / samplesPerBeat;
    final noteEnv = (noteProgress < 0.08)
        ? (noteProgress / 0.08)
        : exp(-(noteProgress - 0.08) * 2.5);
    final vibrato = sin(2 * pi * 5.5 * t) * 4.0; // 5.5 Hz vibrato
    final leadFreq = currentNote + vibrato;
    // Warm rich lead tone
    final leadSignal = (0.28 * sin(2 * pi * leadFreq * t) +
            0.12 * sin(2 * pi * leadFreq * 2 * t) +
            0.05 * sin(2 * pi * leadFreq * 3 * t)) *
        noteEnv;

    // Left and Right Stereo separation
    final backingLeft = (backingMono * 0.95 + chordSignal * 0.15).clamp(-0.95, 0.95);
    final backingRight = (backingMono * 0.95 - chordSignal * 0.15).clamp(-0.95, 0.95);

    // Karaoke audio = Backing track only
    final karaokeLeftInt = (backingLeft * 32767).toInt();
    final karaokeRightInt = (backingRight * 32767).toInt();
    karaokeBuffer[i * 2] = karaokeLeftInt;
    karaokeBuffer[i * 2 + 1] = karaokeRightInt;

    // Normal audio = Backing + Vocal/Lead Melody
    final normalLeft = (backingLeft * 0.75 + leadSignal * 0.7).clamp(-0.95, 0.95);
    final normalRight = (backingRight * 0.75 + leadSignal * 0.7).clamp(-0.95, 0.95);
    normalBuffer[i * 2] = (normalLeft * 32767).toInt();
    normalBuffer[i * 2 + 1] = (normalRight * 32767).toInt();
  }

  // Save Normal WAV
  final normalWav = createWav(normalBuffer, sampleRate, 2);
  File('assets/audio/normal/$name.wav').writeAsBytesSync(normalWav);

  // Save Karaoke WAV
  final karaokeWav = createWav(karaokeBuffer, sampleRate, 2);
  File('assets/audio/karaoke/$name.wav').writeAsBytesSync(karaokeWav);

  print('Created: assets/audio/normal/$name.wav and assets/audio/karaoke/$name.wav');
}

Uint8List createWav(Int16List samples, int sampleRate, int channels) {
  final byteRate = sampleRate * channels * 2;
  final blockAlign = channels * 2;
  final dataSize = samples.length * 2;
  final fileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);

  // RIFF header
  buffer.setUint8(0, 0x52); // 'R'
  buffer.setUint8(1, 0x49); // 'I'
  buffer.setUint8(2, 0x46); // 'F'
  buffer.setUint8(3, 0x46); // 'F'
  buffer.setUint32(4, fileSize, Endian.little);
  buffer.setUint8(8, 0x57);  // 'W'
  buffer.setUint8(9, 0x41);  // 'A'
  buffer.setUint8(10, 0x56); // 'V'
  buffer.setUint8(11, 0x45); // 'E'

  // fmt subchunk
  buffer.setUint8(12, 0x66); // 'f'
  buffer.setUint8(13, 0x6D); // 'm'
  buffer.setUint8(14, 0x74); // 't'
  buffer.setUint8(15, 0x20); // ' '
  buffer.setUint32(16, 16, Endian.little); // Subchunk1Size
  buffer.setUint16(20, 1, Endian.little);  // AudioFormat = PCM
  buffer.setUint16(22, channels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, blockAlign, Endian.little);
  buffer.setUint16(34, 16, Endian.little); // 16 bits per sample

  // data subchunk
  buffer.setUint8(36, 0x64); // 'd'
  buffer.setUint8(37, 0x61); // 'a'
  buffer.setUint8(38, 0x74); // 't'
  buffer.setUint8(39, 0x61); // 'a'
  buffer.setUint32(40, dataSize, Endian.little);

  // PCM data
  int offset = 44;
  for (int i = 0; i < samples.length; i++) {
    buffer.setInt16(offset, samples[i], Endian.little);
    offset += 2;
  }

  return buffer.buffer.asUint8List();
}
