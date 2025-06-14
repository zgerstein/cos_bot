import Foundation
import AVFoundation
import Combine

class RecordingManager: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var microphonePermissionGranted = false
    @Published private(set) var zoomDeviceAvailable = false
    @Published private(set) var micDeviceAvailable = false
    
    private let captureSession = AVCaptureSession()
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var zoomDevice: AVCaptureDevice?
    private var micDevice: AVCaptureDevice?
    private var startCompletion: ((Error?) -> Void)?
    private var stopCompletion: ((Error?) -> Void)?
    
    // Device monitoring
    private var deviceCheckTimer: Timer?
    var onDeviceStatusUpdate: ((Bool, Bool) -> Void)?
    
    // Audio level monitoring
    private var audioLevelUpdateTimer: Timer?
    var onAudioLevelsUpdate: ((Float, Float) -> Void)?
    
    private let recordingsDirectory: URL = {
        let fileManager = FileManager.default
        // Use the specified path for recordings
        let recordingsDir = URL(fileURLWithPath: "/Users/z0g03eg/Documents/Projects/MeetingRecordings")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: recordingsDir.path) {
            try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        }
        
        return recordingsDir
    }()
    
    private var currentRecordingURL: URL?
    private var temporaryRecordingURL: URL?
    
    private func generateRecordingFilename() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "Recording-\(timestamp).m4a"
        return recordingsDirectory.appendingPathComponent(filename)
    }
    
    private func setupTemporaryRecordingFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFilename = "temp_recording_\(UUID().uuidString).m4a"
        return tempDir.appendingPathComponent(tempFilename)
    }
    
    override init() {
        super.init()
        checkMicrophonePermission()
        startDeviceMonitoring()
    }
    
    deinit {
        stopDeviceMonitoring()
    }
    
    private func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionGranted = true
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                    if granted {
                        self?.setupCaptureSession()
                    }
                }
            }
        case .denied, .restricted:
            microphonePermissionGranted = false
        @unknown default:
            microphonePermissionGranted = false
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        // Configure session for high quality audio
        captureSession.sessionPreset = .high
        
        do {
            // Get both audio devices
            zoomDevice = try AudioDeviceHelper.findZoomAudioDevice()
            micDevice = try AudioDeviceHelper.getDefaultMicrophone()
            
            // Add Zoom audio input first (stereo)
            if let zoomDevice = zoomDevice,
               let zoomInput = try? AVCaptureDeviceInput(device: zoomDevice),
               captureSession.canAddInput(zoomInput) {
                captureSession.addInput(zoomInput)
                print("Added Zoom audio input: \(zoomDevice.localizedName)")
            }
            
            // Add microphone input (mono)
            if let micDevice = micDevice,
               let micInput = try? AVCaptureDeviceInput(device: micDevice),
               captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
                print("Added microphone input: \(micDevice.localizedName)")
            }
            
            // Create and configure movie file output
            let movieFileOutput = AVCaptureMovieFileOutput()
            
            // Configure audio settings for AAC, 48kHz, stereo
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48000.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 256000,  // Increased bitrate for better quality
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            if captureSession.canAddOutput(movieFileOutput) {
                captureSession.addOutput(movieFileOutput)
                
                // Configure audio connection
                if let audioConnection = movieFileOutput.connection(with: .audio) {
                    audioConnection.isEnabled = true
                    
                    // Set the output settings
                    movieFileOutput.setOutputSettings(audioSettings, for: audioConnection)
                    print("Configured audio output with settings: \(audioSettings)")
                    
                    // Enable audio level monitoring for all channels
                    for (index, channel) in audioConnection.audioChannels.enumerated() {
                        channel.isEnabled = true
                        print("Enabled audio channel \(index): \(channel)")
                    }
                }
                
                self.movieFileOutput = movieFileOutput
            }
            
            // Print device info for debugging
            if let zoomDevice = zoomDevice {
                print("Zoom device: \(AudioDeviceHelper.getDeviceInfo(zoomDevice))")
            }
            if let micDevice = micDevice {
                print("Mic device: \(AudioDeviceHelper.getDeviceInfo(micDevice))")
            }
            
        } catch {
            print("Error setting up audio devices: \(error)")
        }
        
        captureSession.commitConfiguration()
        
        // Start the capture session
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    private func startAudioLevelMonitoring() {
        audioLevelUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let movieFileOutput = self.movieFileOutput,
                  let audioConnection = movieFileOutput.connection(with: .audio) else { return }
            
            // Get audio levels from both channels
            let zoomLevel = audioConnection.audioChannels[0].averagePowerLevel
            let micLevel = audioConnection.audioChannels[1].averagePowerLevel
            
            // Convert dB to linear scale (0.0 to 1.0)
            // Normalize the levels to a more visible range
            let zoomLinear = max(0.0, min(1.0, pow(10.0, (zoomLevel + 60.0) / 20.0)))
            let micLinear = max(0.0, min(1.0, pow(10.0, (micLevel + 60.0) / 20.0)))
            
            // Print audio levels for debugging
            if zoomLinear > 0.01 || micLinear > 0.01 {  // Lowered threshold to catch more audio
                print("Audio levels - Zoom: \(zoomLinear) (\(zoomLevel) dB), Mic: \(micLinear) (\(micLevel) dB)")
            }
            
            // Update UI on main thread
            DispatchQueue.main.async { [weak self] in
                self?.onAudioLevelsUpdate?(zoomLinear, micLinear)
            }
        }
    }
    
    func startRecording(completion: @escaping (Error?) -> Void) {
        guard microphonePermissionGranted else {
            completion(NSError(domain: "RecordingManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Microphone access is required but not granted"]))
            return
        }
        
        guard !isRecording else {
            completion(NSError(domain: "RecordingManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recording already in progress"]))
            return
        }
        
        // Ensure we have both devices before starting
        guard zoomDevice != nil && micDevice != nil else {
            let error = NSError(domain: "RecordingManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required audio devices"])
            completion(error)
            return
        }
        
        startCompletion = completion
        
        // Generate final and temporary URLs
        currentRecordingURL = generateRecordingFilename()
        temporaryRecordingURL = setupTemporaryRecordingFile()
        
        print("Starting recording to temporary file: \(temporaryRecordingURL!.path)")
        
        // Ensure capture session is running
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
        
        // Then start recording to temporary file
        movieFileOutput?.startRecording(to: temporaryRecordingURL!, recordingDelegate: self)
        isRecording = true
        
        // Start audio level monitoring
        startAudioLevelMonitoring()
        
        // Print initial audio levels
        if let audioConnection = movieFileOutput?.connection(with: .audio) {
            print("Initial audio levels:")
            for (index, channel) in audioConnection.audioChannels.enumerated() {
                print("Channel \(index): \(channel.averagePowerLevel) dB")
            }
        }
    }
    
    func stopRecording(completion: @escaping (Error?) -> Void) {
        guard isRecording else {
            completion(NSError(domain: "RecordingManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "No recording in progress"]))
            return
        }
        
        stopCompletion = completion
        movieFileOutput?.stopRecording()
        isRecording = false
        
        // Stop audio level monitoring
        audioLevelUpdateTimer?.invalidate()
        audioLevelUpdateTimer = nil
    }
    
    private func startDeviceMonitoring() {
        // Initial check
        checkDeviceStatus()
        
        // Start polling every 2 seconds
        deviceCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkDeviceStatus()
        }
    }
    
    private func stopDeviceMonitoring() {
        deviceCheckTimer?.invalidate()
        deviceCheckTimer = nil
    }
    
    func teardown() {
        // Stop any active recording
        if isRecording {
            stopRecording { error in
                if let error = error {
                    print("Error stopping recording during teardown: \(error)")
                }
            }
        }
        
        // Stop device monitoring
        stopDeviceMonitoring()
        
        // Stop audio level monitoring
        audioLevelUpdateTimer?.invalidate()
        audioLevelUpdateTimer = nil
        
        // Stop capture session
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        // Clean up temporary files
        if let tempURL = temporaryRecordingURL {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Reset state
        isRecording = false
        currentRecordingURL = nil
        temporaryRecordingURL = nil
        startCompletion = nil
        stopCompletion = nil
    }
    
    private func checkDeviceStatus() {
        let zoomAvailable = (try? AudioDeviceHelper.findZoomAudioDevice()) != nil
        let micAvailable = (try? AudioDeviceHelper.getDefaultMicrophone()) != nil
        
        DispatchQueue.main.async { [weak self] in
            self?.zoomDeviceAvailable = zoomAvailable
            self?.micDeviceAvailable = micAvailable
            self?.onDeviceStatusUpdate?(zoomAvailable, micAvailable)
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension RecordingManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording: \(error)")
            stopCompletion?(error)
            return
        }
        
        // Move the temporary file to the final location atomically
        if let finalURL = currentRecordingURL {
            do {
                let fileManager = FileManager.default
                
                // If a file already exists at the destination, remove it first
                if fileManager.fileExists(atPath: finalURL.path) {
                    try fileManager.removeItem(at: finalURL)
                }
                
                // Move the temporary file to the final location
                try fileManager.moveItem(at: outputFileURL, to: finalURL)
                print("Recording saved to: \(finalURL.path)")
                stopCompletion?(nil)
            } catch {
                print("Error moving recording to final location: \(error)")
                stopCompletion?(error)
            }
        } else {
            print("No final URL set for recording")
            stopCompletion?(NSError(domain: "RecordingManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Internal error: No final URL set"]))
        }
        
        // Clean up temporary file if it still exists
        if let tempURL = temporaryRecordingURL {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Reset URLs
        currentRecordingURL = nil
        temporaryRecordingURL = nil
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording to: \(fileURL.path)")
        startCompletion?(nil)
    }
} 