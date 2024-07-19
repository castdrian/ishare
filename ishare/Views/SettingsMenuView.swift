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
            .frame(minWidth: 150, idealWidth: 200, maxWidth: 300, maxHeight: .infinity)

            GeneralSettingsView()
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 300, maxHeight: 300)
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
        VStack(alignment: .leading) {
            Spacer()

            HStack {
                VStack(alignment: .leading) {
                    LaunchAtLogin.Toggle()
                    Toggle("Land down under", isOn: $aussieMode)
                }.padding(25)

                Spacer()

                VStack {
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
            }.padding(25)

            Spacer()

            VStack(alignment: .leading) {
                Text("Toast Timeout: \(Int(toastTimeout)) seconds")
                Slider(value: $toastTimeout, in: 1 ... 10, step: 1)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom)
        }
        .padding().rotationEffect(aussieMode ? .degrees(180) : .zero)
    }
}

struct KeybindSettingsView: View {
    @Default(.aussieMode) var aussieMode

    var body: some View {
        Spacer()

        Form {
            KeyboardShortcuts.Recorder("Open Main Menu:", name: .toggleMainMenu)
            KeyboardShortcuts.Recorder("Open History Window:", name: .openHistoryWindow)
            KeyboardShortcuts.Recorder("Capture Region:", name: .captureRegion)
            KeyboardShortcuts.Recorder("Capture Window:", name: .captureWindow)
            KeyboardShortcuts.Recorder("Capture Screen:", name: .captureScreen)
            KeyboardShortcuts.Recorder("Record Screen:", name: .recordScreen)
            KeyboardShortcuts.Recorder("Record GIF:", name: .recordGif)
        }

        Spacer()

        Button(action: {
            KeyboardShortcuts.reset([.toggleMainMenu, .openHistoryWindow, .captureRegion, .captureWindow, .captureScreen, .recordScreen, .recordGif])
            BezelNotification.show(messageText: "Reset keybinds", icon: ToastIcon)
        }) {
            Text("Reset All Keybinds")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
        }
        .padding().rotationEffect(aussieMode ? .degrees(180) : .zero)
    }
}

struct CaptureSettingsView: View {
    @Default(.capturePath) var capturePath
    @Default(.captureFileType) var fileType
    @Default(.captureFileName) var fileName
    @Default(.aussieMode) var aussieMode

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
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
            }.padding()

            VStack(alignment: .leading) {
                Text("File prefix:").font(.headline)
                HStack {
                    TextField(String(), text: $fileName)
                    Button(action: {
                        fileName = Defaults.Keys.captureFileName.defaultValue
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }.help("Set to default")
                }
            }.padding()

            VStack(alignment: .leading) {
                Text("Format:").font(.headline)
                Picker("Format:", selection: $fileType) {
                    ForEach(FileType.allCases, id: \.self) {
                        Text($0.rawValue.uppercased())
                    }
                }.labelsHidden()
            }.padding()

        }.padding().rotationEffect(aussieMode ? .degrees(180) : .zero)
    }
}

struct RecordingSettingsView: View {
    @Default(.recordingPath) var recordingPath
    @Default(.recordingFileName) var fileName
    @Default(.recordMP4) var recordMP4
    @Default(.useHEVC) var useHEVC
    @Default(.useHDR) var useHDR
    @Default(.aussieMode) var aussieMode

    @State private var isExcludedAppSheetPresented = false

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 25) {
                VStack(alignment: .leading) {
                    Toggle("Record .mp4 instead of .mov", isOn: $recordMP4)
                    Toggle("Use HEVC", isOn: $useHEVC)
                    Toggle("Use HDR", isOn: $useHDR)
                }
            }.padding(.horizontal)

            Spacer()

            VStack(alignment: .leading) {
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
            }.padding(.horizontal)

            Spacer()

            VStack(alignment: .leading) {
                Text("File prefix:").font(.headline)
                HStack {
                    TextField(String(), text: $fileName)
                    Button(action: {
                        fileName = Defaults.Keys.recordingFileName.defaultValue
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }.help("Set to default")
                }
            }.padding(.horizontal)

            Spacer()

            Button("Excluded applications") {
                isExcludedAppSheetPresented.toggle()
            }.padding()
                .sheet(isPresented: $isExcludedAppSheetPresented) {
                    ExcludedAppsView().frame(maxHeight: 500)
                }
        }.rotationEffect(aussieMode ? .degrees(180) : .zero)
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
