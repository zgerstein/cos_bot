import Foundation
import SwiftUI
import AVFoundation

@MainActor
class RecordingViewModel: ObservableObject {
    private let recordingManager: RecordingManager
    
    @Published var isRecording = false
    @Published var zoomAudioLevel: Float = 0.0
    @Published var micAudioLevel: Float = 0.0
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var zoomDeviceAvailable = false
    @Published var micDeviceAvailable = false
    
    init(recordingManager: RecordingManager = RecordingManager()) {
        self.recordingManager = recordingManager
        setupAudioLevelMonitoring()
        setupDeviceMonitoring()
    }
    
    private func setupAudioLevelMonitoring() {
        recordingManager.onAudioLevelsUpdate = { [weak self] zoomLevel, micLevel in
            Task { @MainActor in
                self?.zoomAudioLevel = zoomLevel
                self?.micAudioLevel = micLevel
            }
        }
    }
    
    private func setupDeviceMonitoring() {
        recordingManager.onDeviceStatusUpdate = { [weak self] zoomAvailable, micAvailable in
            Task { @MainActor in
                self?.zoomDeviceAvailable = zoomAvailable
                self?.micDeviceAvailable = micAvailable
                
                // Only show error if we're not recording and devices are missing
                guard let self = self else { return }
                if !self.isRecording {
                    var missingDevices: [String] = []
                    if !zoomAvailable {
                        missingDevices.append("Zoom audio")
                    }
                    if !micAvailable {
                        missingDevices.append("microphone")
                    }
                    
                    if !missingDevices.isEmpty {
                        self.errorMessage = "Missing required audio devices: \(missingDevices.joined(separator: " and ")). Please ensure all devices are connected."
                        self.showError = true
                    }
                }
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            recordingManager.stopRecording { [weak self] error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.showError = true
                    }
                    self?.isRecording = false
                }
            }
        } else {
            recordingManager.startRecording { [weak self] error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.showError = true
                    } else {
                        self?.isRecording = true
                        self?.errorMessage = nil
                        self?.showError = false
                    }
                }
            }
        }
    }
    
    func checkAudioDevices() {
        do {
            _ = try AudioDeviceHelper.findZoomAudioDevice()
            _ = try AudioDeviceHelper.getDefaultMicrophone()
            
            Task { @MainActor in
                self.errorMessage = nil
                self.showError = false
            }
        } catch {
            Task { @MainActor in
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    // TODO: Implement audio level monitoring for VU meters
    // This will be implemented in a future task when we add the audio level monitoring
    // functionality to RecordingManager
} 