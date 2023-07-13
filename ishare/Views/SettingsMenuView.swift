//
//  SettingsMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

struct SettingsMenuView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            UploaderSettingsView()
                .tabItem {
                    Label("Uploaders", systemImage: "icloud.and.arrow.up")
                }
            
            KeybindSettingsView()
                .tabItem {
                    Label("Keybinds", systemImage: "command.circle")
                }
            
            CaptureSettingsView()
                .tabItem {
                    Label("Captures", systemImage: "photo")
                }
            
            RecordingSettingsView()
                .tabItem {
                    Label("Recordings", systemImage: "menubar.dock.rectangle.badge.record")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "hammer.circle")
                }
        }
        .frame(width: 550, height: 350)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        LaunchAtLogin.Toggle()
    }
}

struct UploaderSettingsView: View {
    var body: some View {
        Text("Custom Uploader Settings")
            .font(.title)
    }
}

struct KeybindSettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Open Main Menu:", name: .toggleMainMenu)
            KeyboardShortcuts.Recorder("Capture Region:", name: .captureRegion)
            KeyboardShortcuts.Recorder("Capture Window:", name: .captureWindow)
            KeyboardShortcuts.Recorder("Capture Screen:", name: .captureScreen)
            KeyboardShortcuts.Recorder("Record Region:", name: .recordRegion)
            KeyboardShortcuts.Recorder("Record Screen:", name: .recordScreen)
        }
    }
}

struct CaptureSettingsView: View {
    @Default(.capturePath) var capturePath
    @Default(.captureFileType) var fileType
    
    var body: some View {
        VStack {
            HStack {
                Text("Capture path:")
                TextField(text: $capturePath) {}
                Button("Select directory") {
                    selectFolder { folderURL in
                        if let url = folderURL {
                            capturePath = url.path()
                        }
                    }
                }
            }.padding(10)
            
            Picker("File format:", selection: $fileType) {
                ForEach(FileType.allCases, id: \.self) {
                    Text($0.rawValue.uppercased())
                }
            }.padding(10)
        }
    }
}

struct RecordingSettingsView: View {
    @State private var showingAlert: Bool = false
    @State private var isInstalling = false
    @State private var installProgress: Double = 0.0
    
    private var alertTitle: String = "Install ffmpeg"
    private var alertMessage: String = "Do you want to install ffmpeg on this Mac?"
    private var alertButtonText: String = "Confirm"
    
    var body: some View {
        VStack {
            HStack {
                Text("ffmpeg status:")
                Button(isFFmpegInstalled() ? "installed" : "not installed") {
                    showingAlert = true
                }
                .buttonStyle(.borderedProminent)
                .tint(isFFmpegInstalled() ? .green : .pink)
                .disabled(isFFmpegInstalled())
                .alert(Text(alertTitle),
                       isPresented: $showingAlert,
                       actions: {
                    Button(alertButtonText) {
                        showingAlert = false
                        installFFmpeg()
                    }
                    Button("Cancel", role: .cancel) {
                        showingAlert = false
                    }
                }, message: {
                    Text(alertMessage)
                }
                )
            }
            if isInstalling {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color(NSColor.windowBackgroundColor))
                    .frame(width: 200, height: 180)
                    .overlay(
                        VStack {
                            Text("Installing FFmpeg...")
                                .foregroundColor(.primary)
                            Text(String(format: "%.0f%%", installProgress))
                                .font(.title2)
                                .foregroundColor(.primary)
                                .padding(.bottom, 8)
                            ProgressView(value: installProgress, total: 100)
                                .progressViewStyle(LinearProgressViewStyle())
                                .accentColor(.blue)
                                .padding(.horizontal)
                        }
                            .padding()
                    )
            }
        }
    }
    func installFFmpeg() {
        isInstalling = true
        
        DispatchQueue.global().async {
            // Simulating installation progress for demonstration purposes
            let totalProgress: Double = 100.0
            let increment: Double = 1.0
            
            while installProgress < totalProgress {
                installProgress += increment
                usleep(20000) // Simulating delay between progress updates
            }
            
            // Install completed
            isInstalling = false
        }
    }
}

struct AdvancedSettingsView: View {
    var body: some View {
        Text("Advanced Settings")
            .font(.title)
    }
}

func selectFolder(completion: @escaping (URL?) -> Void) {
    let folderPicker = NSOpenPanel()
    folderPicker.canChooseDirectories = true
    folderPicker.canChooseFiles = false
    folderPicker.allowsMultipleSelection = false
    folderPicker.canDownloadUbiquitousContents = true
    folderPicker.canResolveUbiquitousConflicts = true
    
    folderPicker.begin { response in
        if response == .OK {
            completion(folderPicker.urls.first)
        } else {
            completion(nil)
        }
    }
}
