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
    
    var body: some View {
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
    }
}

struct RecordingSettingsView: View {
    var body: some View {
        Text("Recording Settings")
            .font(.title)
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
