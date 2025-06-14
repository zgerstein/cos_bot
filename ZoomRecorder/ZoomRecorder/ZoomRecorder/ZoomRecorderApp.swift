//
//  ZoomRecorderApp.swift
//  ZoomRecorder
//
//  Created by Zach Gerstein on 6/13/25.
//

import SwiftUI

@main
struct ZoomRecorderApp: App {
    // Create a shared RecordingManager instance
    @StateObject private var recordingManager = RecordingManager()
    @State private var isWindowVisible = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recordingManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Add a quit command to handle graceful shutdown
            CommandGroup(replacing: .appTermination) {
                Button("Quit ZoomRecorder") {
                    // Perform teardown before quitting
                    recordingManager.teardown()
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        
        // Add menu bar extra
        MenuBarExtra {
            Button(isWindowVisible ? "Hide Window" : "Show Window") {
                toggleWindow()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Quit") {
                recordingManager.teardown()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "mic.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 18))
        }
    }
    
    private func toggleWindow() {
        if let window = NSApplication.shared.windows.first {
            if isWindowVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            isWindowVisible.toggle()
        }
    }
}
