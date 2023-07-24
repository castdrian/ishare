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
import UniformTypeIdentifiers

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
            
            PluginSettingsView()
                .tabItem {
                    Label("Plugins", systemImage: "puzzlepiece")
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
    @Default(.menuBarAppIcon) var menuBarAppIcon
    
    var body: some View {
        VStack {
            LaunchAtLogin.Toggle()
            Toggle("Use app icon in menubar", isOn: $menuBarAppIcon)
            HStack {
                Button("Export settings") {
                        exportUserDefaults()
                }
                Button("Import settings") {
                        importUserDefaults()
                }
            }
        }
    }
}

struct KeybindSettingsView: View {
    var body: some View {
        VStack {
            Form {
                KeyboardShortcuts.Recorder("Open Main Menu:", name: .toggleMainMenu)
                KeyboardShortcuts.Recorder("Capture Region:", name: .captureRegion)
                KeyboardShortcuts.Recorder("Capture Window:", name: .captureWindow)
                KeyboardShortcuts.Recorder("Capture Screen:", name: .captureScreen)
                KeyboardShortcuts.Recorder("Record Region:", name: .recordRegion)
                KeyboardShortcuts.Recorder("Record Screen:", name: .recordScreen)
            }
            Button("Reset") {
                KeyboardShortcuts.reset([.toggleMainMenu, .captureRegion, .captureWindow, .captureScreen, .recordRegion, .recordScreen])
            }
        }
    }
}

struct CaptureSettingsView: View {
    @Default(.capturePath) var capturePath
    @Default(.captureFileType) var fileType
    @Default(.captureFileName) var fileName
    
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
            
            HStack {
                Text("File name:")
                TextField(String(), text: $fileName)
                Button("Default") {
                    fileName = Defaults.Keys.captureFileName.defaultValue
                }
            }.padding(20)
            
            Picker("File format:", selection: $fileType) {
                ForEach(FileType.allCases, id: \.self) {
                    Text($0.rawValue.uppercased())
                }
            }.padding(10)
        }
    }
}

struct PluginSettingsView: View {
    @State private var isDraggedOver = false
    
    var body: some View {
        VStack {
            Text("Plugin Settings")
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 450, height: 225)
                
                Text("Drop plugins here")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding().onDrop(of: [.fileURL], isTargeted: $isDraggedOver) { providers in
                return handleDrop(providers: providers)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSURL.self) {
                provider.loadObject(ofClass: NSURL.self) { item, error in
                    if let url = item as? URL {
                        print("Received file URL: \(url)")
                    }
                }
            }
        }
        return true
    }
}

struct AdvancedSettingsView: View {
    @State private var showingAlert: Bool = false
    @Default(.imgurClientId) var imgurClientId
    @Default(.captureBinary) var captureBinary
    
    var body: some View {
        VStack{
            HStack {
                Text("Imgur Client ID:")
                TextField(String(), text: $imgurClientId)
                Button("Default") {
                    imgurClientId = Defaults.Keys.imgurClientId.defaultValue
                }
            }.padding(20)
            HStack {
                Text("Screencapture binary:")
                TextField(String(), text: $captureBinary)
                Button("Default") {
                    imgurClientId = Defaults.Keys.captureBinary.defaultValue
                }
            }.padding(20)
            
        }.alert(Text("Advanced Settings"),
                isPresented: $showingAlert,
                actions: {
            Button("I understand") {
                showingAlert = false
            }
        }, message: {
            Text("Warning! Only modify these settings if you know what you're doing!")
        }
        )
        .onAppear{
            showingAlert = true
        }
    }
}
