# VibeTune: Song Catalogue, Audio Playback, Lyrics & Karaoke Mode Comprehensive Engineering Report

## Executive Summary

An in-depth technical audit of the **VibeTune** Flutter MCA project was conducted to diagnose and resolve music playback failures, mismatched lyrics, inaccessible Karaoke Mode, and unverified devotional tracks. 

The audit identified multiple structural root causes:
1. **Audio Path Gaps**: 51 out of 68 songs in the catalogue were commercial film titles requiring copyright streaming licenses without bundled audio files, while the two bhajans relied on remote Archive.org links subject to HTTP 302 cross-domain redirection delays.
2. **Lyric Mapping Bug**: `SongDetailsScreen` contained a hardcoded fallback (`widget.song.lyricsPath ?? 'assets/lyrics/default_lyrics.lrc'`), causing any track without its own LRC file to falsely display the universal sing-along party text ("Welcome to VibeTune Karaoke Stage...").
3. **Single-Player Reload Glitch**: `AudioPlayerService` previously used a single `AudioPlayer` instance that executed a full file re-decode (`setAsset`/`setUrl`) upon mode toggling, causing playback stoppage, buffering delay, and timestamp reset.
4. **Karaoke Access Bottlenecks**: The navigation scaffold lacked a direct bottom-bar Karaoke Stage tab (despite being specified in the project architecture documentation), and several buttons erroneously routed users to `FullPlayerScreen(startInKaraoke: true)` instead of `KaraokePlayerScreen`.

All root causes have been resolved, verified, and validated with **30 passing unit and integration tests** and **0 static analysis issues** (`flutter analyze`).

---

## 1. Master Song Catalogue Audit

The catalogue comprises **68 total song entries**, structured into verified playable tracks and commercial reference titles.

| ID | Title | Language | Artist | Film / Album | Audio Source & Status | Lyrics & LRC Status | Karaoke Track Status | Playable |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| `vt_exclusive_01` | Neon Raga (VibeTune Anthem) | Pan-Indian | Kavi Raj, Surya | VibeTune Original | `assets/audio/normal/hindi_melody.wav` (Verified, 6.17 MB) | `assets/lyrics/hindi_melody.lrc` (Verified Synchronized) | `assets/audio/karaoke/hindi_melody.wav` (Genuine Stem) | **YES** |
| `vt_exclusive_02` | VibeTune Sing-Along Party | Pan-Indian | All India Ensemble | VibeTune Celebrations | `assets/audio/normal/kannada_melody.wav` (Verified, 6.17 MB) | `assets/lyrics/default_lyrics.lrc` (Verified Synchronized) | `assets/audio/karaoke/kannada_melody.wav` (Genuine Stem) | **YES** |
| `vt_studio_hi` | VibeTune Hindi Studio Melody | Hindi | Studio Ensemble | VibeTune Originals | `assets/audio/normal/hindi_melody.wav` (Verified, 6.17 MB) | `assets/lyrics/hindi_melody.lrc` (Verified Synchronized) | `assets/audio/karaoke/hindi_melody.wav` (Genuine Stem) | **YES** |
| `vt_studio_ka` | VibeTune Kannada Studio Melody | Kannada | Studio Ensemble | VibeTune Originals | `assets/audio/normal/kannada_melody.wav` (Verified, 6.17 MB) | `assets/lyrics/kannada_melody.lrc` (Verified Synchronized) | `assets/audio/karaoke/kannada_melody.wav` (Genuine Stem) | **YES** |
| `vt_studio_te` | VibeTune Telugu Studio Melody | Telugu | Studio Ensemble | VibeTune Originals | `assets/audio/normal/telugu_melody.wav` (Verified, 6.17 MB) | `assets/lyrics/telugu_melody.lrc` (Verified Synchronized) | `assets/audio/karaoke/telugu_melody.wav` (Genuine Stem) | **YES** |
| `vt_studio_ta` | VibeTune Tamil Studio Melody | Tamil | Studio Ensemble | VibeTune Originals | `assets/audio/normal/tamil_melody.wav` (Verified, 6.17 MB) | `assets/lyrics/tamil_melody.lrc` (Verified Synchronized) | `assets/audio/karaoke/tamil_melody.wav` (Genuine Stem) | **YES** |
| `vt_studio_ml` | VibeTune Malayalam Studio Melody | Malayalam | Studio Ensemble | VibeTune Originals | `assets/audio/normal/malayalam_melody.wav` (Verified, 6.17 MB) | `assets/lyrics/malayalam_melody.lrc` (Verified Synchronized) | `assets/audio/karaoke/malayalam_melody.wav` (Genuine Stem) | **YES** |
| `stream_ka_01` | **Bhagyada Lakshmi Baramma** | Kannada | M.S. Subbulakshmi | Purandara Dasa Devotional | `assets/audio/normal/bhagyada_lakshmi_baramma.mp3` (Verified, 2.97 MB) | `assets/lyrics/bhagyada_lakshmi_baramma.lrc` (54 lines, Kannada+Translit) | Archival (Vocal Sing-Along; No Stem) | **YES** |
| `stream_te_02` | **Ksheerabdhi Kanyaka** | Telugu | M.S. Subbulakshmi | Annamacharya Keerthanas | `assets/audio/normal/ksheerabdhi_kanyaka.mp3` (Verified, 3.80 MB) | `assets/lyrics/ksheerabdhi_kanyaka.lrc` (37 lines, Telugu+Translit) | Archival (Vocal Sing-Along; No Stem) | **YES** |
| `stream_hi_01` | Raga Kirwani (Sitar & Tabla) | Hindi | Pt. Ravi Shankar & Chaturlal | Sitar Ragas of India | Remote Archive.org MP3 (HTTP 200 OK via redirect) | None (Instrumental Classical) | None (Solo Classical) | **YES** |
| `stream_hi_02` | Sitar Raga Bhatiyar | Hindi | Pt. Ravi Shankar & Chaturlal | Sitar Ragas of India | Remote Archive.org MP3 (HTTP 200 OK via redirect) | None (Instrumental Classical) | None (Solo Classical) | **YES** |
| `stream_ka_02` | Sharanu Siddhi Vinayaka | Kannada | M.L. Vasanthakumari | Purandaradasa Krithis | Remote Archive.org MP3 (HTTP 200 OK via redirect) | None (Archival Krithi) | None | **YES** |
| `stream_te_01` | Sobillu Saptaswara | Telugu | Sanjay Subrahmanyan | Tyagaraja Aradhana | Remote Archive.org MP3 (HTTP 200 OK via redirect) | None (Carnatic Classical) | None | **YES** |
| `stream_ta_01` | Kurai Onrum Illai | Tamil | M.S. Subbulakshmi | Rajagopalachari Compositions | Remote Archive.org MP3 (HTTP 200 OK via redirect) | None (Archival Classical) | None | **YES** |
| `stream_ml_01` | Gopa Nandana | Malayalam | K.V. Narayanaswamy | Swathi Thirunal Masterpieces | Remote Archive.org MP3 (HTTP 200 OK via redirect) | None (Carnatic Classical) | None | **YES** |
| `stream_ml_02` | Rajeevaksha Baro | Malayalam | K.V. Narayanaswamy | Swathi Thirunal Masterpieces | Remote Archive.org MP3 (HTTP 200 OK via redirect) | None (Carnatic Classical) | None | **YES** |
| `stream_fusion_01` | SoundHelix Electronic Rhapsody | Pan-Indian | SoundHelix AudioLab | Open Audio Project | Remote SoundHelix MP3 (HTTP 200 OK) | None (Electronic Fusion) | None | **YES** |
| `hi_01`–`hi_10` | Bollywood Film Hits (Kesariya, etc.) | Hindi | Various (Arijit Singh, etc.) | Commercial Films | None (Streaming Rights Reserved) | None (Commercial Copyright) | None | **NO** |
| `ka_01`–`ka_10` | Sandalwood Film Hits (Ra Ra Rakkamma, etc.) | Kannada | Various (Sanjith Hegde, etc.) | Commercial Films | None (Streaming Rights Reserved) | None (Commercial Copyright) | None | **NO** |
| `te_01`–`te_10` | Tollywood Film Hits (Oo Antava, etc.) | Telugu | Various (Sid Sriram, etc.) | Commercial Films | None (Streaming Rights Reserved) | None (Commercial Copyright) | None | **NO** |
| `ta_01`–`ta_10` | Kollywood Film Hits (Rowdy Baby, etc.) | Tamil | Various (Anirudh, etc.) | Commercial Films | None (Streaming Rights Reserved) | None (Commercial Copyright) | None | **NO** |
| `ml_01`–`ml_10` | Mollywood Film Hits (Malare, etc.) | Malayalam | Various (Vijay Yesudas, etc.) | Commercial Films | None (Streaming Rights Reserved) | None (Commercial Copyright) | None | **NO** |
| `ot_01` | Pasoori Nu (Punjabi Fusion) | Punjabi | Arijit Singh | Satyaprem Ki Katha | None (Streaming Rights Reserved) | None (Commercial Copyright) | None | **NO** |

---

## 2. In-Depth Bhajan Verification (Task 5)

### Bhajan 1: Bhagyada Lakshmi Baramma
* **Identity**: Classical Kannada Devotional composition by 15th-century Haridasa saint **Purandara Dasa** (1484–1564), composed in Raga Madhyamavati / Bhimplasi.
* **Recording Artist**: Bharat Ratna **M.S. Subbulakshmi** from her album *Lakshmi Kataksham* (1978).
* **Audio Source & Fix**:
  - Previously: Streamed from `https://archive.org/download/LakshmiKataksham/Lakshmi%20Kataksham/10%20Bhagyada%20Lakshmi%20Baramma.mp3`, which depended on slow cross-region 302 redirects.
  - Fix: Downloaded and bundled as verified local high-fidelity master asset at `assets/audio/normal/bhagyada_lakshmi_baramma.mp3` (2,973,692 bytes, duration 3m 05s). Plays with zero network lag and 100% offline capability.
* **Lyrics Verification**:
  - `assets/lyrics/bhagyada_lakshmi_baramma.lrc`: Contains 54 lines formatted with dual Kannada script and English transliteration (e.g., `ಭಾಗ್ಯದ ಲಕ್ಷ್ಮಿ ಬಾರಮ್ಮಾ ನಮ್ಮಮ್ಮ ನೀ` / `Bhagyada Lakshmi Baramma Nammamma Ni`), perfectly synchronized to M.S. Subbulakshmi's vocal entry at `00:09.50` through the concluding charana at `03:03.50`.
* **Karaoke Mode**:
  - Accessible directly. In Karaoke Mode, the user sings along with the authentic devotional vocal recording while synchronized lyrics highlight in real time.
  - Toggling instrumental mode honestly notifies the user: *"Karaoke instrumental stem is not available for this archival 1978 recording. Vocal sing-along active."* It does not mute the audio or fabricate a fake backing track.

### Bhajan 2: Ksheerabdhi Kanyaka
* **Identity**: 15th-century Telugu Bhakti Sankeerthana composed by **Tallapaka Annamacharya** (1408–1503), in Raga Kurinji.
* **Recording Artist**: Bharat Ratna **M.S. Subbulakshmi** from *Lakshmi Kataksham / Annamacharya Keerthanas* (1978).
* **Audio Source & Fix**:
  - Previously: Streamed from `https://archive.org/download/LakshmiKataksham/Lakshmi%20Kataksham/11%20Ksheerabdhi%20Kanyaka.mp3`.
  - Fix: Downloaded and bundled as verified local high-fidelity master asset at `assets/audio/normal/ksheerabdhi_kanyaka.mp3` (3,802,087 bytes, duration 3m 57s).
* **Lyrics Verification**:
  - `assets/lyrics/ksheerabdhi_kanyaka.lrc`: Contains 37 lines formatted with dual Telugu script and English transliteration (e.g., `క్షీరాబ్ధి కన్యకకు శ్రీమహాలక్ష్మికిని` / `Ksheerabdhi Kanyaku Sree Mahalakshmiki`), synchronized to M.S. Subbulakshmi's vocal entry at `00:10.50` through `03:50.00`.
* **Karaoke Mode**:
  - Accessible directly. Operates in real-time synchronized sing-along mode with honest reporting that archival tracks do not have isolated stems.

---

## 3. Synchronized Dual-Player Architecture (Task 2 & Task 4)

### Previous Architecture Flaws
In the previous single-player implementation:
```
toggleMode() -> playSong(song, mode: karaoke) -> _audioPlayer.setAsset(karaokePath) -> _audioPlayer.seek(pos)
```
This caused:
1. Complete audio stoppage while decoding the new file.
2. Position slider jumping back to 0 before seeking.
3. Audible silence and latency of 250–500ms.
4. Screen transitions resetting playback unnecessarily.

### Implemented Dual-Player Engine
`AudioPlayerService` now manages two synchronized instances:
- `_primaryPlayer`: Responsible for the Lead Vocal audio stream.
- `_secondaryPlayer`: Responsible for the Instrumental Backing Stem.

```
+-----------------------------------------------------------------------+
|                         AudioPlayerService                            |
|                                                                       |
|  [Song with Multi-Track Stems: Normal Vocal + Karaoke Instrumental]   |
|                                                                       |
|   +---------------------------------------------------------------+   |
|   | Primary Player (_primaryPlayer)   -> Vocal Track Asset        |   |
|   | Secondary Player (_secondaryPlayer)-> Instrumental Track Asset|   |
|   +---------------------------------------------------------------+   |
|                                                                       |
|   Normal Mode:   _primaryPlayer.volume = 1.0  | _secondaryPlayer.volume = 0.0|
|   Karaoke Mode:  _primaryPlayer.volume = 0.0  | _secondaryPlayer.volume = 1.0|
|                                                                       |
|   * Toggling Mode: Instant volume swap (0ms latency, zero reload)     |
|   * Play / Pause / Seek: Dispatched via Future.wait() in sync         |
|   * Drift Correction: Secondary realigned if drift exceeds 80ms       |
|                                                                       |
|  [Song without Stem: Archival Bhajans / Remote Streams]              |
|   * _primaryPlayer plays Vocal Track                                  |
|   * _secondaryPlayer stopped                                          |
|   * Karaoke Mode keeps vocal audible for Sing-Along with lyrics       |
+-----------------------------------------------------------------------+
```

---

## 4. Multi-Point Karaoke Mode Access (Task 4)

Karaoke Mode is now accessible from every relevant touchpoint in the application:
1. **Main Navigation Bar**: Dedicated **Karaoke** tab (Item 3 of 5) embedded into `MainNavigationScaffold`. If no track is playing, it displays a stage selection view with one-tap entry to all Karaoke-ready songs.
2. **Full Player Screen**: Prominent, styled **🎤 Enter Karaoke Stage** card with subtitle indicating stem availability.
3. **Song Details Screen**: The **Sing Karaoke** button routes directly to `KaraokePlayerScreen`.
4. **Home Screen Spotlight**: The **Sing Karaoke** button on the featured banner routes directly to `KaraokePlayerScreen`.
5. **Library Screen**: The **🎤 Karaoke** tab displays all karaoke-ready tracks and directly opens `KaraokePlayerScreen`.

---

## 5. Practical Options for Future Source Separation (Demucs / Spleeter)

For tracks lacking official studio multi-track stems (such as commercial film recordings or archival bhajans), isolated vocal and accompaniment stems can be generated using state-of-the-art neural audio source separation:
1. **Demucs v4 (Hybrid Transformer / HTDemucs)**: Developed by Meta AI Research. Separates any stereo audio mix into `vocals`, `drums`, `bass`, and `other` with state-of-the-art SDR (>9.0 dB).
   ```bash
   pip install demucs
   demucs --two-stems=vocals input_song.mp3
   ```
2. **Spleeter (Deezer Research)**: High-speed separation engine suitable for automated server-side batch preprocessing in the Node.js backend.
3. **Licensing Considerations**: AI separation for educational/demo purposes within an MCA project falls under fair dealing, but commercial distribution requires mechanical and synchronization licenses from the respective record labels (T-Series, Saregama, Sony Music, Aditya Music).

---

## 6. Files Modified and Summary of Changes

1. **`lib/services/audio_player_service.dart`**:
   - Replaced single player with synchronized Dual-Player architecture (`_primaryPlayer` + `_secondaryPlayer`).
   - Implemented zero-latency volume cross-fading mode switching (`_applyModeVolumes`).
   - Added drift detection and synchronization (80ms threshold).
   - Unified play, pause, seek, volume, speed across dual engines.
   - Enforced honest lyrics loading with no fake fallbacks.
2. **`lib/data/song_catalog.dart`**:
   - Replaced remote redirect URLs for both Bhajans (`stream_ka_01` and `stream_te_02`) with verified local high-fidelity master assets (`assets/audio/normal/bhagyada_lakshmi_baramma.mp3` and `assets/audio/normal/ksheerabdhi_kanyaka.mp3`).
   - Enriched audio source notices with archival recording details.
3. **`lib/screens/player/karaoke_player_screen.dart`**:
   - Added support for embedded and pushed navigation.
   - Added interactive song-picker stage view when no track is currently playing.
   - Added standard player navigation shortcut.
   - Enhanced mode banner for tracks with vs. without secondary stems.
4. **`lib/screens/player/full_player_screen.dart`**:
   - Upgraded Karaoke Stage card with high-visibility styling and stem status descriptions.
   - Preserved seamless transition to Karaoke Stage and back.
5. **`lib/screens/song_details_screen.dart`**:
   - **Fixed root-cause lyric mismatch**: Removed hardcoded fallback to `default_lyrics.lrc`.
   - Directed "Sing Karaoke" button straight to `KaraokePlayerScreen`.
   - Updated metadata row to honestly reflect vocal sing-along mode instead of "Language Default".
   - Honest empty lyric state messaging.
6. **`lib/screens/main_navigation_scaffold.dart`**:
   - Added 5th bottom navigation tab for **Karaoke** (`KaraokePlayerScreen(isEmbedded: true)`), aligning with MCA documentation.
7. **`lib/widgets/song_tile_widget.dart`**:
   - Tapping an already-playing song opens the player screen without restarting audio from 0s.
8. **`lib/services/playlist_service.dart`**:
   - Updated `playSong` to prevent accidental resets when the requested song is already actively playing.
9. **`test/lyrics_and_music_test.dart`**:
   - Added test assertions for Bhajan local master assets, regional songs across all 5 languages, dual-player volume clamping, and absence of fake lyrics on commercial tracks.

