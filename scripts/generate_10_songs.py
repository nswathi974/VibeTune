import struct, wave, math, random, os

def generate_full_song_pair(filename, base_freq, tempo_bpm, chord_prog, melody_pattern, duration_sec=40.0):
    framerate = 44100
    num_frames = int(framerate * duration_sec)
    beat_dur = 60.0 / tempo_bpm
    
    backing_l = [0.0] * num_frames
    backing_r = [0.0] * num_frames
    vocal_l = [0.0] * num_frames
    vocal_r = [0.0] * num_frames
    
    total_beats = int(duration_sec / beat_dur)
    
    # 1. RHYTHM & DRUMS
    kick_samples = int(0.18 * framerate)
    snare_samples = int(0.22 * framerate)
    hh_samples = int(0.04 * framerate)
    
    for b in range(total_beats):
        b_start = int(b * beat_dur * framerate)
        # Kick on 0, 2
        if b % 2 == 0:
            for i in range(min(kick_samples, num_frames - b_start)):
                t = i / framerate
                f = 135.0 * math.exp(-t * 26.0) + 42.0
                env = math.exp(-t * 14.0)
                v = 0.55 * math.sin(2 * math.pi * f * t) * env
                backing_l[b_start + i] += v
                backing_r[b_start + i] += v
        else: # Snare on 1, 3
            for i in range(min(snare_samples, num_frames - b_start)):
                t = i / framerate
                env = math.exp(-t * 17.0)
                noise = (random.random() * 2.0 - 1.0) * 0.32 * env
                tone = 0.22 * math.sin(2 * math.pi * 195.0 * t) * math.exp(-t * 24.0)
                v = (noise + tone) * 0.95
                backing_l[b_start + i] += v
                backing_r[b_start + i] += v
                
        # Hi-hat on 8th notes
        for sub in [0, 0.5]:
            hh_start = b_start + int(sub * beat_dur * framerate)
            if hh_start < num_frames:
                for i in range(min(hh_samples, num_frames - hh_start)):
                    t = i / framerate
                    env = math.exp(-t * 65.0)
                    h = (random.random() * 2.0 - 1.0) * 0.12 * env
                    backing_l[hh_start + i] += h * 0.8
                    backing_r[hh_start + i] += h * 1.1

    # 2. BASS & HARMONIC CHORDS
    for b in range(total_beats):
        chord_root = chord_prog[(b // 4) % len(chord_prog)]
        b_start = int(b * beat_dur * framerate)
        b_len = int(beat_dur * framerate)
        
        # Bassline
        root_f = base_freq * (2.0 ** ((chord_root - 24) / 12.0))
        for i in range(min(b_len, num_frames - b_start)):
            t = i / framerate
            env = math.exp(-t * 3.2)
            bass = 0.38 * (math.sin(2 * math.pi * root_f * t) + 0.3 * math.sin(4 * math.pi * root_f * t)) * env
            backing_l[b_start + i] += bass
            backing_r[b_start + i] += bass
            
        # Pad chord harmony
        for interval in [0, 4, 7]:
            pf = base_freq * (2.0 ** ((chord_root + interval - 12) / 12.0))
            for i in range(min(b_len, num_frames - b_start)):
                t = (b_start + i) / framerate
                env = 0.13 * (1.0 + 0.15 * math.sin(2 * math.pi * 0.6 * t))
                val = (math.sin(2 * math.pi * pf * t) + 0.2 * math.sin(6 * math.pi * pf * t)) * env
                backing_l[b_start + i] += val * 0.85
                backing_r[b_start + i] += val * 1.15

    # 3. VOCAL STEM (Only active in Normal version)
    for b in range(min(total_beats, len(melody_pattern) * 2)):
        note = melody_pattern[(b // 1) % len(melody_pattern)]
        if note is not None:
            vf = base_freq * (2.0 ** (note / 12.0))
            b_start = int(b * beat_dur * framerate)
            b_len = int(beat_dur * 0.88 * framerate)
            for i in range(min(b_len, num_frames - b_start)):
                t = i / framerate
                vib = 1.0 + 0.018 * math.sin(2 * math.pi * 5.8 * t)
                freq = vf * vib
                lead = (math.sin(2 * math.pi * freq * t)
                        + 0.52 * math.sin(4 * math.pi * freq * t)
                        + 0.28 * math.sin(6 * math.pi * freq * t)
                        + 0.15 * math.sin(8 * math.pi * freq * t)
                        + 0.08 * math.sin(10 * math.pi * freq * t))
                env = min(1.0, t * 18.0) * math.exp(-t * 1.8)
                val = lead * env * 0.48
                vocal_l[b_start + i] += val
                vocal_r[b_start + i] += val

    # Render WAV files
    os.makedirs('assets/audio/normal', exist_ok=True)
    os.makedirs('assets/audio/karaoke', exist_ok=True)
    
    k_path = f'assets/audio/karaoke/{filename}.wav'
    n_path = f'assets/audio/normal/{filename}.wav'
    
    kw = wave.open(k_path, 'w')
    kw.setnchannels(2); kw.setsampwidth(2); kw.setframerate(framerate)
    
    nw = wave.open(n_path, 'w')
    nw.setnchannels(2); nw.setsampwidth(2); nw.setframerate(framerate)
    
    k_bytes = bytearray()
    n_bytes = bytearray()
    
    for i in range(num_frames):
        kl = max(-1.0, min(1.0, backing_l[i]))
        kr = max(-1.0, min(1.0, backing_r[i]))
        nl = max(-1.0, min(1.0, backing_l[i] + vocal_l[i]))
        nr = max(-1.0, min(1.0, backing_r[i] + vocal_r[i]))
        
        k_bytes.extend(struct.pack('<hh', int(kl * 32767), int(kr * 32767)))
        n_bytes.extend(struct.pack('<hh', int(nl * 32767), int(nr * 32767)))
        
    kw.writeframes(k_bytes)
    nw.writeframes(n_bytes)
    kw.close()
    nw.close()
    print(f"Generated stems for: {filename}")

# 10 Diverse Musical Songs Definitions
songs_config = [
    {
        'file': 'kesariya',
        'freq': 261.63, # C4
        'tempo': 96,
        'chord': [0, 7, 9, 5],
        'melody': [0, 2, 4, 7, 7, 9, 7, 4, 5, 4, 2, 0, 2, 4, 2, 0]
    },
    {
        'file': 'tum_hi_ho',
        'freq': 220.00, # A3
        'tempo': 90,
        'chord': [0, 3, 7, 5],
        'melody': [0, 3, 5, 7, 8, 7, 5, 3, 5, 7, 5, 3, 2, 3, 2, 0]
    },
    {
        'file': 'belageddu',
        'freq': 293.66, # D4
        'tempo': 108,
        'chord': [0, 5, 7, 0],
        'melody': [0, 4, 7, 9, 12, 9, 7, 4, 7, 9, 7, 4, 2, 4, 2, 0]
    },
    {
        'file': 'singara_siriye',
        'freq': 246.94, # B3
        'tempo': 102,
        'chord': [0, 7, 5, 9],
        'melody': [0, 2, 4, 5, 7, 9, 11, 12, 11, 9, 7, 5, 4, 2, 4, 0]
    },
    {
        'file': 'butta_bomma',
        'freq': 329.63, # E4
        'tempo': 112,
        'chord': [0, 7, 9, 5],
        'melody': [0, 2, 4, 7, 9, 7, 4, 2, 4, 7, 9, 11, 9, 7, 4, 0]
    },
    {
        'file': 'samajavaragamana',
        'freq': 277.18, # C#4
        'tempo': 94,
        'chord': [0, 4, 7, 11],
        'melody': [0, 3, 5, 7, 7, 10, 8, 7, 5, 7, 5, 3, 2, 3, 0, 0]
    },
    {
        'file': 'rowdy_baby',
        'freq': 349.23, # F4
        'tempo': 118,
        'chord': [0, 5, 7, 5],
        'melody': [0, 4, 7, 9, 7, 4, 0, 2, 4, 7, 9, 12, 9, 7, 4, 0]
    },
    {
        'file': 'enjoy_enjaami',
        'freq': 261.63, # C4
        'tempo': 100,
        'chord': [0, 8, 5, 7],
        'melody': [0, 3, 5, 7, 8, 10, 8, 7, 5, 7, 5, 3, 5, 3, 2, 0]
    },
    {
        'file': 'malare_ninne',
        'freq': 220.00, # A3
        'tempo': 88,
        'chord': [0, 5, 7, 4],
        'melody': [0, 2, 4, 7, 9, 7, 4, 2, 0, 2, 4, 5, 4, 2, 0, 0]
    },
    {
        'file': 'darshana',
        'freq': 293.66, # D4
        'tempo': 105,
        'chord': [0, 7, 9, 5],
        'melody': [0, 2, 4, 7, 9, 12, 9, 7, 4, 7, 9, 7, 4, 2, 0, 0]
    }
]

for s in songs_config:
    generate_full_song_pair(s['file'], s['freq'], s['tempo'], s['chord'], s['melody'], duration_sec=40.0)

print("All 10 normal and karaoke stems generated successfully!")
