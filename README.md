# ZoomRecorder

A macOS application that captures both Zoom audio and system microphone input simultaneously, perfect for recording online meetings with local audio commentary.

## Features

- 🎙️ Simultaneous recording of Zoom audio and system microphone
- 📊 Real-time VU meters for both audio sources
- 🎯 High-quality audio capture (AAC, 48 kHz, stereo)
- 🚀 Quick access through menu bar
- ♿ VoiceOver accessibility support
- 🔒 Secure file handling with atomic writes

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.10
- Microphone access permission
- Zoom application installed (for Zoom audio capture)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ZoomRecorder.git
```

2. Open `ZoomRecorder.xcodeproj` in Xcode

3. Configure your development team in the project settings

4. Build and run the application

## Usage

1. Launch ZoomRecorder from the menu bar icon
2. Ensure Zoom is running and a meeting is active
3. Click the Record button (●) to start recording
4. Monitor audio levels using the VU meters
5. Click the Stop button (■) to end recording

Recordings are saved to: `~/Library/Application Support/Recordings/` with the format: `Recording-YYYYMMDD-HHMMSS.m4a`

## Development

### Project Structure

- `RecordingManager.swift` - Core audio capture session logic
- `AudioDeviceHelper.swift` - Audio device discovery and management
- `RecordingViewModel.swift` - UI binding and state management
- `ContentView.swift` - Main SwiftUI interface
- `ZoomRecorderApp.swift` - Application entry point

### Testing

The project includes unit tests for core functionality. Run tests using:
```bash
xcodebuild test -scheme ZoomRecorder
```

## License

[Add your license here]

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Support

[Add support information here] 