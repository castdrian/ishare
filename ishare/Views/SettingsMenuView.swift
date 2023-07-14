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
    @State private var errorAlert: ErrorAlert? = nil
    @State private var isFFmpegInstalled: Bool = false

    
    private var alertTitle: String = "Install ffmpeg"
    private var alertMessage: String = "Do you want to install ffmpeg on this Mac?"
    private var alertButtonText: String = "Confirm"
    
    var body: some View {
        VStack {
            HStack {
                Text("ffmpeg status:")
                Button(isFFmpegInstalled ? "installed" : "not installed") {
                    showingAlert = true
                }
                .buttonStyle(.borderedProminent)
                .tint(isFFmpegInstalled ? .green : .pink)
                .disabled(isFFmpegInstalled)
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
            }.onAppear {
                isFFmpegInstalled = checkFFmpegInstallation()
            }
            if isInstalling {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color(NSColor.windowBackgroundColor))
                    .frame(width: 200, height: 180)
                    .overlay(
                        VStack {
                            ProgressView {
                                Text("Installing ffmpeg...")
                                    .foregroundColor(.primary)
                            }
                            .progressViewStyle(CircularProgressViewStyle())
                            .accentColor(.blue)
                            .padding(.horizontal)
                        }
                        .padding()
                    )
            }
        }
        .alert(item: $errorAlert) { error in
            error.alert
        }
    }
    
    func installFFmpeg() {
        isInstalling = true
        
        DispatchQueue.global().async {
            let process = Process()
            process.launchPath = "/usr/local/bin/brew"
            process.arguments = ["install", "ffmpeg"]
            
            process.launch()
            process.waitUntilExit()
            
            DispatchQueue.main.async {
                isInstalling = false
                
                if process.terminationStatus != 0 {
                    errorAlert = ErrorAlert(
                        title: "Installation Failed",
                        message: "Failed to install ffmpeg. Please try again."
                    )
                }
            }
        }
    }
}

struct ErrorAlert: Identifiable {
    var id = UUID()
    var title: String
    var message: String
    
    var alert: Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("OK"))
        )
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
