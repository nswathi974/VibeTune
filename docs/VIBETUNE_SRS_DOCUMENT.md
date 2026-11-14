# Department of MCA
## Software Requirements Specification (SRS)
### IEEE SRS FORMAT – REFERENCE DOCUMENT
**(Applicable for Enterprise Applications / Mobile & Web Cross-Platform Systems)**

---

# VIBETUNE
### Next-Generation Multilingual Music Streaming & Synchronized Karaoke Platform

| Document Attribute | Specification Details |
| :--- | :--- |
| **Project Title** | VibeTune (Cross-Platform Audio & Karaoke System) |
| **Document Standard** | IEEE Std 830-1998 / ISO/IEC/IEEE 29148 Compliant |
| **Academic Department** | Department of Master of Computer Applications (MCA) |
| **Academic Year** | 2025 – 2026 |
| **Status / Version** | Version 1.0 (Final Approved Baseline) |
| **Author / Prepared By** | Swathi (Lead MCA Software Engineering Team) |
| **Core Technology Stack** | Flutter SDK (Dart 3.x), just_audio DSP, Provider State Management, SharedPreferences, RESTful APIs |

---

## Table of Contents
1. [1. Introduction](#1-introduction)
   - 1.1 Purpose of this Document
   - 1.2 Scope of this Document
   - 1.3 Overview – Summary of the Project
2. [2. General Description](#2-general-description)
   - 2.1 User Objectives & Product Perspective
   - 2.2 User Characteristics & Target Audience
   - 2.3 Core Features & System Capabilities
   - 2.4 Product Benefits & Technical Rationale (Importance)
   - 2.5 Features of the User Community & Stakeholders
3. [3. External Interface Requirements](#3-external-interface-requirements)
   - 3.1 User Interfaces (UI/UX Specifications)
   - 3.2 Hardware Interfaces
   - 3.3 Software Interfaces
   - 3.4 Communication Interfaces
4. [4. Functional Requirements](#4-functional-requirements)
   - 4.1 Interface Requirements & Functional Module Breakdown
   - 4.2 Performance Requirements (Operational Functionality)
   - 4.3 Design Constraints
5. [5. Non-Functional Attributes](#5-non-functional-attributes)
   - 5.1 Performance Attributes
   - 5.2 Security Attributes
   - 5.3 Reliability Attributes
   - 5.4 Usability Attributes
   - 5.5 Scalability Attributes
6. [6. Preliminary Schedule & Project Plan](#6-preliminary-schedule)
   - 6.1 Development Lifecycle & Phases
   - 6.2 Work Breakdown Structure (WBS) & Milestones
7. [7. Future Enhancements](#7-future-enhancements)
8. [8. Appendices](#8-appendices)
   - 8.1 Definitions, Acronyms, and Abbreviations
   - 8.2 Data Dictionary & Entity Schemas
   - 8.3 References & Standards

---

## 1. Introduction

### 1.1 Purpose of this Document
The purpose of this Software Requirements Specification (SRS) document is to provide a complete, rigorous, and definitive description of the software architecture, functional requirements, external interface parameters, and non-functional quality attributes of **VibeTune**. 

This document serves as the foundational agreement between developers, system architects, project guides, faculty evaluators in the Department of Master of Computer Applications (MCA), and prospective end-users. It delineates the behavioral specifications of the VibeTune platform, guiding the iterative software engineering lifecycle, validation regimens, and post-deployment maintenance.

### 1.2 Scope of this Document
The scope of this document encompasses the design, implementation, and deployment of the **VibeTune** system—an enterprise-grade, cross-platform audio streaming, lyric synchronization, and interactive karaoke application. 

Specifically, the document defines:
- The mobile and desktop client application constructed using Google’s Flutter SDK.
- The dual-channel audio stem playback pipeline (Vocal Melody track vs. Instrumental Backing track).
- The dynamic LRC (Lyric File) parser with real-time millisecond-precise lyric synchronization.
- Local state management, cached persistence, and user profile configuration systems.
- Network communication protocols, external streaming service adapters, and hardware digital-to-analog converter (DAC) interfaces.
- The system boundaries, operational limitations, safety parameters, and architectural constraints.

### 1.3 Overview – Summary of the Project
**VibeTune** is a rich, modern music application created to bridge the divide between passive audio listening and active musical participation. While conventional music services (e.g., Spotify, Apple Music) treat karaoke as an afterthought—often relying on third-party lyric feeds or lower-fidelity automated filters—VibeTune integrates an instantaneous **Dual-Mode Audio Engine**:
1. **Normal Studio Mode:** Plays high-fidelity full master audio recordings with studio vocals.
2. **Karaoke Stage Mode:** Seamlessly transitions audio execution to a dedicated studio-recorded instrumental stem while preserving playback position, accompanied by dynamic, auto-scrolling lyric teleprompting with visual beat markers.

VibeTune pays particular tribute to the linguistic richness of the Indian subcontinent, featuring a curated multilingual catalog of 52+ iconic tracks spanning **Bollywood (Hindi)**, **Kannada**, **Telugu**, **Tamil**, **Malayalam**, and **Pan-Indian Fusion**. Built atop a dark-neon aesthetic design system, VibeTune brings low-latency audio buffering, customized playlists, heart-based favorites, and personalized playback telemetry directly to users' handheld and desktop devices.

---

## 2. General Description

### 2.1 User Objectives & Product Perspective
#### User Objectives
The primary objectives of users adopting VibeTune include:
- Seamlessly streaming regional and pan-Indian music in crystal-clear audio quality without playback latency or visual clutter.
- Switching instantaneously from passive listening to active vocal performance (Karaoke) with a single tap, without losing playback progress or song tempo.
- Practicing singing along with synchronized, timestamped lyrics highlighting each line in real time.
- Organizing personal musical collections into favorites, recent logs, and language-specific filtered lists.
- Controlling audio parameters including playback speed (0.5x to 2.0x), volume balancing, repeat loops, and shuffle sequences.

#### Product Perspective
VibeTune functions as a comprehensive, self-contained cross-platform client-side application with modular cloud-ready service interfaces:
- **Presentation Layer (Flutter UI):** Reactive UI components structured with Material 3 design tokens, glassmorphism card surfaces, vibrant neon indicators, and responsive layouts.
- **State Management & Business Logic Layer (`Provider`):** `AudioPlayerService` handles audio stream events; `PlaylistService` governs catalog filtering, active queue indexing, and favorites; `AuthService` handles authentication and session tokens.
- **Audio DSP Engine (`just_audio`):** Interfaces directly with native platform audio hardware and low-level codecs (MediaCodec on Android, AVPlayer on iOS, WASAPI on Windows).
- **Data Persistence Layer (`shared_preferences` & local asset bundle):** Caches user preferences, favorited song IDs, playback history, and stores pre-packaged high-res stems and LRC manifests.

```
+-------------------------------------------------------------------------+
|                              VibeTune UI                                |
|   Home  |  Search  |  Full Player  |  Karaoke Stage  |  Library | Profile|
+-------------------------------------------------------------------------+
                                     |
               (Reactive State via Provider ChangeNotifier)
                                     v
+-------------------------------------------------------------------------+
|                          Business Logic Services                        |
|   AudioPlayerService    |   PlaylistService    |     AuthService        |
|   (Playback Engine)     | (Queue, Filters, Fav)| (Profiles & Auth)      |
+-------------------------------------------------------------------------+
            |                                       |
  (Audio Stream / Stems)                 (State & Storage)
            v                                       v
+-----------------------+              +----------------------------------+
| just_audio Core & DSP |              |  SharedPreferences & JSON Cache  |
+-----------------------+              +----------------------------------+
            |                                       |
    (Hardware Codec)                     (Native Local Storage)
            v                                       v
[ Android OpenSL / iOS CoreAudio ]       [ Flash Memory / SQLite / JSON ]
```

### 2.2 User Characteristics & Target Audience
The system caters to three main user archetypes:
1. **Casual Music Enthusiasts:** Users who desire quick access to regional hits, trending playlists, and simple one-tap listening with elegant album art.
2. **Aspiring Singers & Karaoke Hobbyists:** Users seeking backing tracks to practice singing, requiring synchronized lyric displays, vocal mute/lead controls, and tempo adjustments.
3. **Regional & Multilingual Audiences:** Users who actively switch between multiple Indian languages (Hindi, Kannada, Telugu, Tamil, Malayalam) and appreciate categorized linguistic discovery.

All user classes are presumed to possess basic familiarity with modern touch-screen mobile devices, standard audio player metaphors (Play, Pause, Seek, Next, Shuffle), and mobile application navigation.

### 2.3 Core Features & System Capabilities
1. **Dual-Track Stem Playback:** Seamless switching between vocal recordings and instrumental karaoke backing tracks while preserving millisecond position.
2. **Synchronized LRC Teleprompter:** High-accuracy timestamped lyric parser that auto-scrolls and highlights the active lyric line synchronously with the audio timeline.
3. **Multilingual Regional Filter Chips:** Dynamic filtering across six Indian musical linguistic categories (`All`, `Hindi`, `Kannada`, `Telugu`, `Tamil`, `Malayalam`).
4. **Persistent Music Library:** Multi-tab personal library managing all tracks, dedicated karaoke-ready collections, user favorites, and recent playback history.
5. **Interactive Mini Player & Persistent Scaffold:** Floating global audio controller enabling uninterrupted listening while navigating different screens.
6. **Smart Search System:** Instant client-side search with debounce over song titles, artists, movies, and a dedicated "Karaoke Only" filter switch.
7. **Customizable Audio DSP Controls:** Variable playback speed (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x), volume slider, loop modes (Off, All, One), and shuffle permutations.
8. **User Profile & Audio Quality Settings:** Personalized profile info, selectable streaming quality presets (320kbps High-Res, 192kbps Standard, 128kbps Data Saver), and volume normalization toggles.

### 2.4 Product Benefits & Technical Rationale (Importance)
- **Eliminates Vocal Bleed:** Traditional automated vocal cancellers introduce phase artifacts and muffled audio; VibeTune utilizes dedicated, studio-produced instrumental stems for high acoustic clarity.
- **Low Barrier to Entry:** Operates seamlessly offline with bundled local assets and scales effortlessly to remote HTTPS audio CDNs.
- **Enhanced Cultural Relevance:** Focuses deeply on Indian languages and regional cinema/independent soundtracks often marginalized in Western-centric streaming applications.
- **Unified Entertainment Hub:** Merges music streaming, lyric exploration, and karaoke into a single consolidated client, eliminating the need for fragmented third-party apps.

### 2.5 Features of the User Community & Stakeholders
| Stakeholder Group | Primary Interest / Responsibility |
| :--- | :--- |
| **End Users (Singers/Listeners)** | Frictionless playback, zero buffer lag, synchronized lyrics, accurate search, high-res audio. |
| **Software Engineering Team** | Maintainable architecture, robust state management, high test coverage, clean code. |
| **Academic Guides & Evaluators** | Verification of IEEE software engineering standards, requirement traceability, structured documentation. |
| **Content Creators & Musicians** | Correct attribution of artist names, movie/album titles, and copyright protection. |

---

## 3. External Interface Requirements

### 3.1 User Interfaces (UI/UX Specifications)
The user interface follows a modern Dark-Neon glassmorphism design system built with Material 3 standards:
- **Color Palette:**
  - Background Base: `#0F111A` (Deep Space Dark)
  - Surface Card: `#161922` (Obsidian Charcoal)
  - Surface Hover: `#1F2430` (Elevated Panel)
  - Primary Accent: `#00F0FF` (Electric Cyan / Playback Active)
  - Secondary Accent: `#8A2BE2` (Neon Purple / Ambient Glow)
  - Karaoke Accent: `#FFD166` (Sunburst Amber / Mic Active)
  - Heart / Favorite Accent: `#FF5376` (Neon Coral)
- **Typography:** Google Fonts *Outfit* & *Inter* with strict hierarchical weighting (Headline 24px bold, Subhead 16px medium, Body 14px regular, Caption 11px muted).
- **Core Screen Hierarchy:**
  1. `SplashScreen`: Branded launch screen displaying animated sound-wave logo and initializing device preferences.
  2. `WelcomeScreen`: First-time user greeting with feature value propositions and Auth entry points.
  3. `SignInScreen` & `SignUpScreen`: Responsive text inputs with real-time validation for credentials.
  4. `MainNavigationScaffold`: Root frame hosting the bottom navigation bar and the floating `MiniPlayerWidget`.
  5. `HomeScreen`: Hero spotlight banner, language chips, karaoke horizontal carousel, and Indian track catalog.
  6. `FullPlayerScreen`: Full-screen vinyl cover artwork, scrub slider, stem mode switch button, lyrics preview card.
  7. `KaraokePlayerScreen`: Atmospheric dark karaoke stage with dynamic glowing spotlight, lyrics prompter, and vocal lead switch.
  8. `SearchScreen`: Search bar with clear button, karaoke filter chip, and real-time result tiles.
  9. `LibraryScreen`: 4-tab controller separating All Songs, Karaoke Tracks, Favorites, and Recently Played.
  10. `SongDetailsScreen`: Extended song information, credits, full lyric sheet view, and playback launcher.
  11. `ProfileScreen`: User avatar, email, audio playback preferences, streaming bitrate options, and storage stats.

### 3.2 Hardware Interfaces
The software interfaces with the following client hardware components via OS-level abstractions:
- **Audio Output Subsystem:** Standard 3.5mm stereo audio jacks, USB-C DAC dongles, built-in device stereo speakers, and wireless Bluetooth A2DP audio profiles.
- **Audio Input Subsystem (Microphone):** Built-in condenser microphones and external wired/Bluetooth headset microphones for vocal monitoring.
- **Touch Screen Display:** Capacitive multi-touch panels supporting tap, horizontal swipe (carousels), vertical scroll (song lists), and drag gestures (progress seek bar and volume sliders).
- **Local Storage Hardware:** Internal Flash ROM / NVMe storage for application assets, SQLite/SharedPreferences databases, and cached audio data.

### 3.3 Software Interfaces
- **Operating Systems:** Android OS (API level 24 / Android 7.0 Nougat and above), iOS (iOS 13.0 and above), Windows 10/11 (x64), and modern evergreen web browsers (Chrome, Edge, Safari, Firefox via Flutter Web).
- **Flutter Framework (v3.13.2+):** Renders all declarative widgets, manages element trees, animations, and handles touch events.
- **Native Audio Plugins (`just_audio`):**
  - *Android:* Google ExoPlayer / Media3 runtime bindings.
  - *iOS / macOS:* Apple AVFoundation (`AVPlayer`, `AVAudioSession`).
  - *Windows:* Media Foundation / WASAPI audio pipelines.
- **Persistence Driver (`shared_preferences`):**
  - *Android:* `SharedPreferences` XML API.
  - *iOS:* `NSUserDefaults` plist engine.
  - *Desktop/Web:* LocalStorage / JSON flat-file storage.
- **YouTube Video Engine (`youtube_player_flutter`):** Embedded webview IFrame renderer for auxiliary video playback.

### 3.4 Communication Interfaces
- **HTTP/HTTPS Protocols:** RFC 2616 / RFC 7230 compliant client-server communication using TLS 1.3 encryption for remote song stream fetching, cover artwork CDN loading, and authentication handshakes.
- **RESTful JSON Services:** Client communicates with backend web services using JSON payloads:
  - Header: `Content-Type: application/json`, `Authorization: Bearer <JWT_TOKEN>`.
- **Media Streaming Protocol:** Range-header HTTP audio chunking supporting partial downloads (`bytes=0-1048576`) to facilitate instant playback initiation and seeking without waiting for full track downloads.

---

## 4. Functional Requirements

### 4.1 Interface Requirements & Functional Module Breakdown

#### Module 1: User Authentication & Profile Subsystem
- **FR-1.1:** System shall permit new users to register an account using Full Name, Email Address, and Password with client-side validation (minimum 6 characters, RFC email format).
- **FR-1.2:** System shall allow registered users to authenticate securely and maintain persistent login sessions across app reboots via encrypted tokens stored in local preferences.
- **FR-1.3:** System shall provide a Guest Mode allowing users to explore the catalog, sample songs, and enter karaoke mode without an account.
- **FR-1.4:** System shall allow users to view and modify their profile settings, audio quality bitrates (320kbps vs 192kbps), and volume normalization toggles.

#### Module 2: Catalog Browsing & Multilingual Filtering
- **FR-2.1:** System shall display a comprehensive catalog of songs with title, artist, album/movie, language, cover art, and duration.
- **FR-2.2:** System shall provide horizontal filter chips for instant filtering by language: `All`, `Hindi`, `Kannada`, `Telugu`, `Tamil`, `Malayalam`.
- **FR-2.3:** System shall highlight a featured track in a high-visibility spotlight card on the Home Screen with direct action buttons to "Play Vocals" or "Sing Karaoke".
- **FR-2.4:** System shall display a dedicated horizontal carousel showcasing tracks with verified karaoke instrumental tracks.

#### Module 3: Advanced Audio Playback Engine
- **FR-3.1:** System shall support continuous, glitch-free audio playback of standard formats (MP3, WAV, AAC, OGG).
- **FR-3.2:** System shall provide full media transport controls: Play, Pause, Resume, Seek, Next Track, and Previous Track.
- **FR-3.3:** System shall allow the user to toggle playback loops (`LoopMode.off`, `LoopMode.all`, `LoopMode.one`) and random track Shuffling.
- **FR-3.4:** System shall permit variable playback speed adjustments in discrete multiples: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, and 2.0x.
- **FR-3.5:** System shall maintain an active persistent `MiniPlayerWidget` docked at the bottom of the navigation frame whenever a song is loaded, showing title, artist, cover thumbnail, play/pause toggle, and full player expansion tap gesture.

#### Module 4: Dual-Track Stem Switching & Interactive Karaoke Mode
- **FR-4.1:** System shall maintain two distinct audio track paths for karaoke-enabled songs:
  1. `normalAudioPath` (full studio recording with master vocals).
  2. `karaokeAudioPath` (studio instrumental backing track with lead vocals eliminated).
- **FR-4.2:** System shall allow switching between `PlaybackMode.normal` and `PlaybackMode.karaoke` dynamically.
- **FR-4.3:** When switching modes, the audio engine shall record the current playback position timestamp ($T_{current}$) and resume the newly selected stem at exactly $T_{current}$ to ensure seamless continuity.
- **FR-4.4:** System shall provide a dedicated `KaraokePlayerScreen` featuring an ambient dark stage aesthetic, dynamic spotlight halo, microphone mode indicators, and vocal lead controls.

#### Module 5: Synchronized Lyric Teleprompting (LRC Engine)
- **FR-5.1:** System shall parse standard timestamped LRC lyric files containing tags in the format `[mm:ss.xx] Lyric text string`.
- **FR-5.2:** System shall dynamically compare the real-time audio playback position with lyric timestamps at a minimum frequency of 20Hz (every 50ms).
- **FR-5.3:** System shall determine the currently active singing line, style it in bright neon font with an enlarged scale, and auto-scroll the lyric list to center the active line on screen.
- **FR-5.4:** The user shall be able to manually tap any lyric line in the teleprompter to trigger an immediate audio seek to that line's start timestamp.

#### Module 6: Search, Library & Favorites Management
- **FR-6.1:** System shall perform real-time debounce search filtering across title, artist name, and movie/album fields.
- **FR-6.2:** System shall provide a "Karaoke Only" toggle filter in the search interface to restrict search results to tracks with available instrumental stems.
- **FR-6.3:** System shall permit users to favorite/unfavorite any song by tapping the heart icon, persisting the favorite state in device storage.
- **FR-6.4:** System shall log every played track into a persistent `Recently Played` list, capped at the most recent 25 songs.
- **FR-6.5:** System shall categorize the Library into 4 distinct tabs: All Songs, Karaoke Only, Favorites, and Recently Played.

### 4.2 Performance Requirements (Operational Functionality)
- **Audio Start Latency:** Local audio playback shall initiate within $\le 80\text{ ms}$ of pressing Play. Remote stream buffering shall begin audible output within $\le 300\text{ ms}$ under 4G/Wi-Fi conditions.
- **Stem Switch Latency:** The handover transition between normal vocal audio and karaoke instrumental audio shall complete within $\le 120\text{ ms}$ with no perceivable gap or pitch artifact.
- **Lyric Sync Accuracy:** The LRC lyric highlighter shall not drift by more than $\pm 50\text{ ms}$ relative to the master audio track clock.
- **Search Response:** Client-side search filtering across a 1,000-song catalog shall return results within $\le 16\text{ ms}$ (under 1 frame budget).

### 4.3 Design Constraints
- **Framework Constraint:** The client codebase must strictly adhere to Flutter 3.x and Dart 3.x guidelines, compiling natively to ARM64/x86_64 binaries without webview wrappers for core playback.
- **Memory Consumption Constraint:** Peak heap memory usage of the application during active karaoke playback with lyric rendering must not exceed $150\text{ MB}$ RAM on mobile devices.
- **Offline Self-Sufficiency:** The system must function gracefully even in the total absence of an internet connection by playing bundled demo tracks and stored local files.
- **Audio Output Standard:** Audio engine output must maintain 16-bit / 44.1kHz CD quality minimum and support 24-bit / 48kHz high-resolution audio.

---

## 5. Non-Functional Attributes

### 5.1 Performance
- **UI Frame Rate:** The graphical interface must maintain a smooth 60 frames per second (FPS) on standard displays and 120 FPS on ProMotion/high-refresh rate mobile panels, with zero frame drops during lyric scrolling.
- **Resource Footprint:** Idle CPU consumption while playing audio in the background must remain below $3\%$ on standard multi-core mobile processors.
- **Storage Footprint:** The compiled client installation package (APK/IPA) must remain under $40\text{ MB}$ excluding bundled local audio media.

### 5.2 Security
- **Authentication Credentials:** User passwords must never be stored in plain text. When connected to a backend, all credential exchange must enforce HTTPS TLS 1.3 encryption.
- **Secure Local Storage:** Sensitive user preferences and session tokens stored via `SharedPreferences` must be partitioned inside application sandboxed storage inaccessible to other installed applications.
- **Input Sanitization:** All text search queries and profile text entry fields must be sanitized against SQL/NoSQL injection and cross-site scripting (XSS) vectors.

### 5.3 Reliability
- **Mean Time Between Failures (MTBF):** The application client shall exhibit an MTBF exceeding 500 operating hours under normal consumer usage.
- **Error Recovery & Resilience:** In the event of a missing audio stem or unparseable lyric file, the application must not crash; it shall display an informative snackbar alert, fall back to default universal lyrics, and gracefully continue audio playback.
- **Audio Session Handling:** The application must listen to OS audio focus notifications: pause audio when receiving incoming phone calls, lower volume (duck) for incoming system notifications, and pause automatically when headphones are unplugged.

### 5.4 Usability
- **Intuitive Visual Hierarchy:** 90% of novice users must be able to discover songs, switch to karaoke mode, and view synchronized lyrics without reading an instruction manual or guide.
- **Color Contrast Ratios:** All text elements against dark surfaces must meet WCAG 2.1 AA standards (minimum contrast ratio of 4.5:1 for body text, 3:1 for large headers).
- **Accessibility:** Interactive buttons and touch targets must measure at least $48 \times 48$ logical pixels in accordance with Material Design accessibility guidelines.

### 5.5 Scalability
- **Catalog Extensibility:** The song catalog architecture must support scaling from 52 songs to 500,000+ tracks via paginated JSON endpoints and virtualized lazy-loading list views (`ListView.builder` / `SliverList`).
- **Concurrent User Scaling:** The stateless client architecture enables horizontal scaling across remote CDN edges, supporting millions of concurrent streaming listeners without client-side modifications.

---

## 6. Preliminary Schedule

### 6.1 Development Lifecycle & Phases
The development of VibeTune is structured across a **16-Week Waterfall-Agile Hybrid Model** tailored for an MCA Capstone Engineering Project:

```
[Week 1-2: Requirements & Feasibility]
       │
       ▼
[Week 3-4: UI/UX & System Architecture]
       │
       ▼
[Week 5-8: Core Audio & Karaoke Engine Implementation]
       │
       ▼
[Week 9-11: Multilingual Catalog, LRC Sync & Library Modules]
       │
       ▼
[Week 12-14: Verification, Quality Assurance & DSP Stress Testing]
       │
       ▼
[Week 15-16: Final Deployment, Documentation & Academic Defense]
```

### 6.2 Work Breakdown Structure (WBS) & Milestones

| Sprint / Phase | Weeks | Key Activities & Deliverables | Milestone Checkpoint |
| :--- | :---: | :--- | :--- |
| **Phase 1: Inception & SRS** | W1 – W2 | Problem definition, requirement elicitation, comparative study of streaming players, drafting IEEE SRS document. | M1: Approved SRS Document |
| **Phase 2: UI/UX Design System** | W3 – W4 | Creation of wireframes, dark-neon color palette, Material 3 theme configuration, screen layout prototypes. | M2: UI/UX Design Freeze |
| **Phase 3: Core Audio Pipeline** | W5 – W8 | Integration of `just_audio`, building `AudioPlayerService`, dual-stem switching logic, audio buffer optimization. | M3: Functional Audio Engine Demo |
| **Phase 4: Karaoke & LRC Integration**| W9 – W11 | Custom LRC timestamp parser, real-time scroll sync, Karaoke Stage screen, 52-song Indian catalog curation. | M4: Integrated Karaoke Stage Demo |
| **Phase 5: Search, Library & Testing**| W12 – W14| Search debounce, multilingual filter chips, Favorites persistence, unit testing, latency profiling. | M5: Beta Release & Test Report |
| **Phase 6: Deployment & Defense** | W15 – W16| Production APK/Bundle build, code refactoring, user documentation, academic project defense viva. | M6: Final Project Submission |

---

## 7. Future Enhancements

The following features are slated for subsequent major versions (v2.0+) of VibeTune:

1. **AI-Powered On-The-Fly Vocal Remover (Demucs / Spleeter Integration):** Integrate a client-side or serverless AI stem separation model enabling users to upload any audio track and extract vocal and karaoke instrumental tracks in real time.
2. **Real-Time Pitch Detection & Vocal Scoring Engine:** Utilize Audio DSP Fast Fourier Transforms (FFT) on microphone input to detect pitch accuracy against the song's lead vocal line and provide an interactive game score (0 to 100%) at the end of each karaoke session.
3. **Social Karaoke Rooms ("VibeParty"):** WebRTC-powered virtual rooms allowing synchronized group karaoke, collaborative playlists, and live voice chat among distributed friends.
4. **Offline Encrypted Song Downloads:** AES-256 encrypted local caching of high-definition audio tracks for seamless offline playback during travel or low connectivity.
5. **AI Music Recommendation System:** Collaborative filtering and emotion-based embedding recommendations analyzing user listening history to suggest new tracks.

---

## 8. Appendices

### 8.1 Definitions, Acronyms, and Abbreviations
- **SRS:** Software Requirements Specification
- **IEEE:** Institute of Electrical and Electronics Engineers
- **MCA:** Master of Computer Applications
- **LRC:** A computer file format that synchronizes text lyrics with an audio file (e.g., MP3/WAV) using line-level timestamps `[mm:ss.xx]`.
- **DSP:** Digital Signal Processing
- **DAC:** Digital-to-Analog Converter
- **Stem:** An individual audio track isolated from a multi-track recording (e.g., vocal stem, instrumental stem).
- **A2DP:** Advanced Audio Distribution Profile (Bluetooth stereo streaming standard)
- **UI / UX:** User Interface / User Experience
- **API:** Application Programming Interface
- **JSON:** JavaScript Object Notation
- **FPS:** Frames Per Second
- **WBS:** Work Breakdown Structure
- **WCAG:** Web Content Accessibility Guidelines

### 8.2 Data Dictionary & Entity Schemas

#### 1. Song Entity Schema
```dart
class Song {
  final String id;                  // Unique identifier (e.g., 'vt_exclusive_01', 'hi_01')
  final String title;               // Song Title
  final String artist;              // Singer / Composer Name
  final String movieOrAlbum;        // Album / Soundtrack Name
  final String language;            // Hindi, Kannada, Telugu, Tamil, Malayalam, Pan-Indian
  final String coverImage;          // Path/URL to album artwork image
  final String normalAudioPath;     // Full master recording with vocal lead
  final String? karaokeAudioPath;   // Instrumental backing track (no vocals)
  final String? lyricsPath;         // LRC synchronized lyric file path
  final Duration duration;          // Total track length
  final int year;                   // Release year (e.g., 2026)
  final String genre;               // Melody, Pop, EDM, Classical, etc.
  final bool isKaraokeAvailable;    // Karaoke availability flag
  final bool hasTimedLyrics;        // LRC timing support flag
}
```

#### 2. Lyric Line Entity Schema
```dart
class LyricLine {
  final Duration timestamp;         // Millisecond timestamp when the line begins
  final String text;                // The lyrical sentence/phrase
}
```

#### 3. User Profile Entity Schema
```dart
class UserModel {
  final String id;                  // Unique user identifier
  final String name;                // User display name
  final String email;               // User email address
  final String? avatarUrl;          // Profile picture reference
  final List<String> favoriteIds;   // Array of favorited song ID strings
}
```

### 8.3 References & Standards
1. **IEEE Std 830-1998:** *IEEE Recommended Practice for Software Requirements Specifications*, IEEE Computer Society, 1998.
2. **ISO/IEC/IEEE 29148:2018:** *Systems and software engineering — Life cycle processes — Requirements engineering*.
3. **Flutter Documentation:** Official Google Flutter Architectural Guide & Best Practices (https://docs.flutter.dev).
4. **Just Audio Audio Specification:** Comprehensive Audio DSP & Stream Handling for Flutter (Ryan Heise, https://pub.dev/packages/just_audio).
5. **Material Design 3 Guidelines:** Google Design System for Modern Touch Interfaces (https://m3.material.io).
