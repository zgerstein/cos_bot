import Foundation
import AVFoundation

class AudioDeviceHelper {
    enum AudioDeviceError: Error {
        case zoomDeviceNotFound
        case defaultMicNotFound
    }
    
    static func findZoomAudioDevice() throws -> AVCaptureDevice {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        
        // Print all available devices for debugging
        print("Available audio devices:")
        for device in discoverySession.devices {
            print("- \(device.localizedName) (ID: \(device.uniqueID))")
        }
        
        // Look for Zoom's virtual audio device
        if let zoomDevice = discoverySession.devices.first(where: { device in
            // Check for both "Zoom" and "zoom" in the name
            let name = device.localizedName.lowercased()
            return (name.contains("zoom") || name.contains("zoom audio") || name.contains("zoomaudio")) && 
                   device.hasMediaType(.audio)
        }) {
            // Verify the device is available
            if zoomDevice.isConnected && !zoomDevice.isSuspended {
                print("Found Zoom device: \(zoomDevice.localizedName)")
                return zoomDevice
            }
        }
        
        throw AudioDeviceError.zoomDeviceNotFound
    }
    
    static func getDefaultMicrophone() throws -> AVCaptureDevice {
        // First try to get the default microphone
        if let defaultMic = AVCaptureDevice.default(for: .audio) {
            // Verify the device is available
            if defaultMic.isConnected && !defaultMic.isSuspended {
                print("Using default microphone: \(defaultMic.localizedName)")
                return defaultMic
            }
        }
        
        // If default mic isn't available, try to find any working microphone
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone],
            mediaType: .audio,
            position: .unspecified
        )
        
        if let workingMic = discoverySession.devices.first(where: { device in
            device.isConnected && !device.isSuspended
        }) {
            print("Using fallback microphone: \(workingMic.localizedName)")
            return workingMic
        }
        
        throw AudioDeviceError.defaultMicNotFound
    }
    
    static func enumerateAudioDevices() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        return discoverySession.devices
    }
    
    static func getDeviceInfo(_ device: AVCaptureDevice) -> String {
        return """
        Name: \(device.localizedName)
        ID: \(device.uniqueID)
        Connected: \(device.isConnected)
        Suspended: \(device.isSuspended)
        Format: \(device.activeFormat.formatDescription)
        """
    }
} 