import Foundation
import AVFoundation

enum AudioDeviceHelper {
    static func findZoomAudioDevice() throws -> AVCaptureDevice {
        // Find the Zoom audio device (application audio)
        let devices = AVCaptureDevice.devices(for: .audio)
        if let zoomDevice = devices.first(where: { $0.localizedName.contains("Zoom") }) {
            return zoomDevice
        }
        throw NSError(domain: "AudioDeviceHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Zoom audio device not found"])
    }
    
    static func getDefaultMicrophone() throws -> AVCaptureDevice {
        // Get the default microphone
        if let micDevice = AVCaptureDevice.default(for: .audio) {
            return micDevice
        }
        throw NSError(domain: "AudioDeviceHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Default microphone not found"])
    }
    
    static func getDeviceInfo(_ device: AVCaptureDevice) -> String {
        return "Name: \(device.localizedName), ID: \(device.uniqueID)"
    }
} 