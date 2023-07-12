//
//  SettingsMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import LaunchAtLogin

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
        Text("Keybind Settings")
            .font(.title)
    }
}

struct AdvancedSettingsView: View {
    var body: some View {
        Text("Advanced Settings")
            .font(.title)
    }
}
