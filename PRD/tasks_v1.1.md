Notes
Unit tests should typically be placed alongside the code files they are testing (e.g., RecordingManager.swift and RecordingManagerTests.swift in the same directory).

Treat every checkbox as an actionable deliverable that a junior developer can complete and mark done.

Tasks
 1.0 [x] Project Bootstrap & Environment Setup

 1.1 [x] Create a new Xcode macOS App (SwiftUI) project named "ZoomRecorder".

 1.2 [x] Add target macOS 14+, Swift 5.10 tool-chain.

 1.3 [x] Configure bundle identifier and code-signing team.

 1.4 [x] Configure file access for ~/Library/Application Support/Recordings (no App Sandbox needed for personal use).

 1.5 [ ] Commit initial scaffold to Git; push to GitHub and enable branch protection rules.

 2.0 [x] Core Audio Capture Engine

 2.1 [x] Create RecordingManager.swift with an AVCaptureSession that supports multiple inputs.

 2.2 Implement AudioDeviceHelper.swift to:

 2.2.1 [x] Enumerate system devices and locate the ZoomAudioDevice (.applicationAudio).

 2.2.2 [x] Retrieve the current default microphone ID.

 2.3 [x] Add both devices to the capture session and route to AVCaptureMovieFileOutput (AAC, 48 kHz, stereo).

 2.4 [x] Implement safe filename generator Recording-YYYYMMDD-HHMMSS.m4a in the recordings folder.

 2.5 [x] Expose startRecording() and stopRecording() methods with completion callbacks.

 3.0 SwiftUI User Interface

 3.1 [x] Create RecordingViewModel.swift that binds UI to RecordingManager.

 3.2 Build ContentView.swift with:

 3.2.1 [x] A central Record ● / Stop ■ toggle button (state-driven colour).

 3.2.2 [x] Two vertical VU meters (Zoom = left, Mic = right) fed by audio-level KVO.

 3.3 [x] Add minimal menu-bar status item to quick-launch the window.

 3.4 Localise VoiceOver accessibility labels for button and meters.

 4.0 Permissions, Error Handling & File Management

 4.1 [x] Update Info.plist with NSMicrophoneUsageDescription.

 4.2 [x] Prompt user for microphone access on first launch; block recording if denied.

 4.3 [x] Display modal error if either audio device is missing; poll every 2 s until found.

 4.4 [x] Ensure .m4a file is finalised atomically on stop (handle abrupt quits).

 4.5 [x] Add graceful teardown on app close (stop active recording, flush buffers).

 5.0 Testing, CI & Demo Assets

 5.1 Write RecordingManagerTests.swift that:

 5.1.1 Starts a 5-second silent recording.

 5.1.2 Asserts file exists and size > 5 kB.

 5.2 Add GitHub Actions workflow (ci.yml) to run unit tests on each pull request with macOS runner.

 5.3 Create DemoScript.md describing the milestone demo steps (Zoom call, record, play in QuickTime).

Relevant Files
File	Purpose
RecordingManager.swift	Core capture session logic
AudioDeviceHelper.swift	Utility for audio-device discovery
RecordingViewModel.swift	ObservableObject binding UI to capture logic
ContentView.swift	SwiftUI interface with record/stop button & VU meters
ZoomRecorderApp.swift	App entry point
Info.plist	Permissions strings and sandbox entitlements
RecordingManagerTests.swift	Automated unit test for file output
.github/workflows/ci.yml	CI pipeline for tests
DemoScript.md	Manual QA & demo instructions