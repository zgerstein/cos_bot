//
//  ContentView.swift
//  ZoomRecorder
//
//  Created by Zach Gerstein on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var recordingManager: RecordingManager
    @StateObject private var viewModel: RecordingViewModel
    
    init() {
        // Initialize with the shared RecordingManager
        _viewModel = StateObject(wrappedValue: RecordingViewModel())
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // VU Meters
            HStack(spacing: 20) {
                VUMeter(level: viewModel.zoomAudioLevel, label: "Zoom")
                    .opacity(viewModel.zoomDeviceAvailable ? 1.0 : 0.3)
                VUMeter(level: viewModel.micAudioLevel, label: "Mic")
                    .opacity(viewModel.micDeviceAvailable ? 1.0 : 0.3)
            }
            .frame(height: 100)
            
            // Device status indicators
            HStack(spacing: 20) {
                HStack {
                    Circle()
                        .fill(viewModel.zoomDeviceAvailable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("Zoom Audio")
                        .font(.caption)
                }
                HStack {
                    Circle()
                        .fill(viewModel.micDeviceAvailable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("Microphone")
                        .font(.caption)
                }
            }
            
            // Record/Stop button
            Button(action: {
                viewModel.toggleRecording()
            }) {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(viewModel.isRecording ? .red : .blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isRecording ? "Stop Recording" : "Start Recording")
            
            // Status text
            Text(viewModel.isRecording ? "Recording..." : "Ready to Record")
                .foregroundColor(.secondary)
        }
        .padding(30)
        .frame(width: 400, height: 350)
        .alert("Recording Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

#Preview {
    ContentView()
}
