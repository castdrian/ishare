//
//  SettingsMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
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
        }
    }
}

struct CaptureSettingsView: View {
    var body: some View {
        Text("Capture Settings")
            .font(.title)
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
