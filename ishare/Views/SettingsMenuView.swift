//
//  SettingsMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//  UI reworked by iGerman on 22.04.24.
//

import BezelNotification
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import ScreenCaptureKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsMenuView: View {
    @Default(.aussieMode) var aussieMode

    let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

    var body: some View {
        NavigationView {
            VStack {
                List {
                    NavigationLink(destination: GeneralSettingsView()) {
                        Label("General", systemImage: "gearshape").rotationEffect(aussieMode ? .degrees(180) : .zero)
                    }
                    NavigationLink(destination: UploaderSettingsView()) {
                        Label("Uploaders", systemImage: "icloud.and.arrow.up").rotationEffect(aussieMode ? .degrees(180) : .zero)
                    }
                    NavigationLink(destination: KeybindSettingsView()) {
                        Label("Keybinds", systemImage: "command.circle").rotationEffect(aussieMode ? .degrees(180) : .zero)
                    }
                    NavigationLink(destination: CaptureSettingsView()) {
                        Label("Image files", systemImage: "photo").rotationEffect(aussieMode ? .degrees(180) : .zero)
                    }
                    NavigationLink(destination: RecordingSettingsView()) {
                        Label("Video files", systemImage: "menubar.dock.rectangle.badge.record").rotationEffect(aussieMode ? .degrees(180) : .zero)
                    }
                    NavigationLink(destination: AdvancedSettingsView()) {
                        Label("Advanced", systemImage: "hammer.circle").rotationEffect(aussieMode ? .degrees(180) : .zero)
                    }
                }
                .listStyle(SidebarListStyle())

                Spacer()
                Divider().padding(.horizontal)
                VStack {
                    Text("v" + appVersionString)
                    Link(destination: URL(string: "https://github.com/castdrian/ishare")!) {
                        Text("GitHub")
                    }
                }
                .rotationEffect(aussieMode ? .degrees(180) : .zero)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(minWidth: 200, idealWidth: 200, maxWidth: 300, maxHeight: .infinity)

            GeneralSettingsView()
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 450, maxHeight: 450)
        .navigationTitle("Settings")
    }
}

struct GeneralSettingsView: View {
    @Default(.menuBarIcon) var menubarIcon
    @Default(.toastTimeout) var toastTimeout
    @Default(.aussieMode) var aussieMode
    @Default(.uploadHistory) var uploadHistory

    let appImage = NSImage(named: "AppIcon") ?? AppIcon

    struct MenuButtonStyle: ButtonStyle {
        var backgroundColor: Color

        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding(10)
                .background(backgroundColor)
                .cornerRadius(5)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack(spacing: 40) {
                VStack(alignment: .leading) {
                    LaunchAtLogin.Toggle()
                    Toggle("Land down under", isOn: $aussieMode)
                }

                VStack(alignment: .leading) {
                    Text("Menu Bar Icon")
                    HStack {
                        ForEach(MenuBarIcon.allCases, id: \.self) { choice in
                            Button(action: {
                                menubarIcon = choice
                            }) {
                                switch choice {
                                case .DEFAULT:
                                    Image(nsImage: GlyphIcon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 20, height: 5)
                                case .APPICON:
                                    Image(nsImage: AppIcon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 20, height: 5)
                                case .SYSTEM:
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 20, height: 5)
                                }
                            }
                            .buttonStyle(
                                MenuButtonStyle(
                                    backgroundColor:
                                    menubarIcon == choice ? .accentColor : .clear)
                            )
                        }
                    }
                }
            }
            .padding(.top, 30)

            Spacer()

            VStack(alignment: .leading) {
                Text("Toast Timeout: \(Int(toastTimeout)) seconds")
                Slider(value: $toastTimeout, in: 1 ... 10, step: 1)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 30)
        }
        .padding(30)
        .rotationEffect(aussieMode ? .degrees(180) : .zero)
    }
}

struct KeybindSettingsView: View {
    @Default(.forceUploadModifier) var forceUploadModifier
    @Default(.aussieMode) var aussieMode

    var body: some View {
        VStack(spacing: 20) {
            Form {
                Section {
                    VStack(spacing: 10) {
                        KeyboardShortcuts.Recorder("Open Main Menu:", name: .toggleMainMenu)
                        KeyboardShortcuts.Recorder("Open History Window:", name: .openHistoryWindow)
                        KeyboardShortcuts.Recorder("Capture Region:", name: .captureRegion)
                        KeyboardShortcuts.Recorder("Capture Window:", name: .captureWindow)
                        KeyboardShortcuts.Recorder("Capture Screen:", name: .captureScreen)
                        KeyboardShortcuts.Recorder("Record Screen:", name: .recordScreen)
                        KeyboardShortcuts.Recorder("Record GIF:", name: .recordGif)
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        HStack {
                            Text("Force Upload Modifier:")
                            Picker("", selection: $forceUploadModifier) {
                                ForEach(ForceUploadModifier.allCases) { modifier in
                                    Text(modifier.rawValue)
                                        .tag(modifier)
                                }
                            }
                            .frame(width: 100)
                        }
                    }
                    .padding(.vertical, 5)
                } header: {
                    Text("Keybinds")
                        .font(.headline)
                        .padding(.bottom, 5)
                }
            }
            .formStyle(.grouped)
            
            Button(action: {
                KeyboardShortcuts.reset([
                    .toggleMainMenu, .openHistoryWindow,
                    .captureRegion, .captureWindow, .captureScreen,
                    .recordScreen, .recordGif,
                    .captureRegionForceUpload, .captureWindowForceUpload, .captureScreenForceUpload,
                    .recordScreenForceUpload, .recordGifForceUpload
                ])
                BezelNotification.show(messageText: "Reset keybinds", icon: ToastIcon)
            }) {
                Text("Reset All Keybinds")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .rotationEffect(aussieMode ? .degrees(180) : .zero)
        }
        .padding()
    }
}

struct CaptureSettingsView: View {
    @Default(.capturePath) var capturePath
    @Default(.captureFileType) var fileType
    @Default(.captureFileName) var fileName
    @Default(.aussieMode) var aussieMode

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Image path:").font(.headline)
                HStack {
                    TextField(text: $capturePath) {}
                    Button(action: {
                        selectFolder { folderURL in
                            if let url = folderURL {
                                capturePath = url.path()
                            }
                        }
                    }) {
                        Image(systemName: "folder.fill")
                    }.help("Pick a folder")
                }
            }

            VStack(alignment: .leading, spacing: 15) {
                Text("File prefix:").font(.headline)
                HStack {
                    TextField(String(), text: $fileName)
                    Button(action: {
                        fileName = Defaults.Keys.captureFileName.defaultValue
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }.help("Set to default")
                }
            }

            VStack(alignment: .leading, spacing: 15) {
                Text("Format:").font(.headline)
                Picker("Format:", selection: $fileType) {
                    ForEach(FileType.allCases, id: \.self) {
                        Text($0.rawValue.uppercased())
                    }
                }
                .labelsHidden()
            }
        }
        .padding(30)
        .rotationEffect(aussieMode ? .degrees(180) : .zero)
    }
}

struct RecordingSettingsView: View {
    @Default(.recordingPath) var recordingPath
    @Default(.recordingFileName) var fileName
    @Default(.recordMP4) var recordMP4
    @Default(.useHEVC) var useHEVC
    @Default(.useHDR) var useHDR
    @Default(.aussieMode) var aussieMode
    @Default(.recordAudio) var recordAudio
    @Default(.recordMic) var recordMic
    @Default(.recordPointer) var recordPointer
    @Default(.recordClicks) var recordClicks
    
    @State private var isExcludedAppSheetPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 30) {
                    VStack(alignment: .leading) {
                        Toggle("Record .mp4 instead of .mov", isOn: $recordMP4)
                        Toggle("Use HEVC", isOn: $useHEVC)
                        Toggle("Use HDR", isOn: $useHDR)
                        Toggle("Record audio", isOn: $recordAudio)
                        Toggle("Record microphone", isOn: $recordMic)
                            .onChange(of: recordMic) { oldValue, newValue in
                                if newValue {
                                    Task {
                                        switch AVCaptureDevice.authorizationStatus(for: .audio) {
                                        case .authorized:
                                            NSLog("Microphone permissions already granted")
                                        case .notDetermined:
                                            NSLog("Requesting microphone permissions")
                                            let granted = await AVCaptureDevice.requestAccess(for: .audio)
                                            if !granted {
                                                NSLog("Microphone permissions denied")
                                                await MainActor.run {
                                                    recordMic = false
                                                }
                                            }
                                            NSLog("Microphone permissions granted")
                                        case .denied, .restricted:
                                            NSLog("Microphone permissions denied or restricted")
                                            await MainActor.run {
                                                recordMic = false
                                            }
                                        @unknown default:
                                            NSLog("Unknown microphone permission status")
                                            await MainActor.run {
                                                recordMic = false
                                            }
                                        }
                                    }
                                }
                            }
                        Toggle("Record pointer", isOn: $recordPointer)
                        Toggle("Record clicks", isOn: $recordClicks)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 15) {
                Text("Video path:").font(.headline)
                HStack {
                    TextField(text: $recordingPath) {}
                    Button(action: {
                        selectFolder { folderURL in
                            if let url = folderURL {
                                recordingPath = url.path()
                            }
                        }
                    }) {
                        Image(systemName: "folder.fill")
                    }.help("Pick a folder")
                }
            }

            VStack(alignment: .leading, spacing: 15) {
                Text("File prefix:").font(.headline)
                HStack {
                    TextField(String(), text: $fileName)
                    Button(action: {
                        fileName = Defaults.Keys.recordingFileName.defaultValue
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }.help("Set to default")
                }
            }

            Button("Excluded applications") {
                isExcludedAppSheetPresented.toggle()
            }
            .padding(.top)
        }
        .padding(30)
        .rotationEffect(aussieMode ? .degrees(180) : .zero)
    }
}

struct AdvancedSettingsView: View {
    @State private var showingAlert: Bool = false
    @Default(.imgurClientId) var imgurClientId
    @Default(.captureBinary) var captureBinary
    @Default(.aussieMode) var aussieMode

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading) {
                Text("Imgur Client ID:").font(.headline)
                HStack {
                    TextField(String(), text: $imgurClientId)
                    Button(action: {
                        imgurClientId = Defaults.Keys.imgurClientId.defaultValue
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }.help("Set to default")
                }
            }
            Spacer()
            VStack {
                VStack(alignment: .leading) {
                    Text("Screencapture binary:").font(.headline)
                    HStack {
                        TextField(String(), text: $captureBinary)
                        Button(action: {
                            captureBinary = Defaults.Keys.captureBinary.defaultValue
                            BezelNotification.show(messageText: "Reset captureBinary", icon: ToastIcon)
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }.help("Set to default")
                    }
                }
            }
            Spacer()
        }.padding().rotationEffect(aussieMode ? .degrees(180) : .zero)
            .alert(Text("Advanced Settings"),
                   isPresented: $showingAlert,
                   actions: {
                       Button("I understand") {
                           showingAlert = false
                       }
                   }, message: {
                       Text("Warning! Only modify these settings if you know what you're doing!")
                   })
            .onAppear {
                showingAlert = true
            }
    }
}

#Preview {
    SettingsMenuView()
}
