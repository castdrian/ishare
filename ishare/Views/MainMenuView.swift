//
//  MainMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults

struct MainMenuView: View {
    @State private var isFFmpegInstalled: Bool = false
    
    @Default(.copyToClipboard) var copyToClipboard
    @Default(.openInFinder) var openInFinder
    @Default(.uploadMedia) var uploadMedia
    @Default(.uploadType) var uploadType
    @Default(.activeCustomUploader) var activeCustomUploader
    @Default(.savedCustomUploaders) var savedCustomUploaders
    
    var body: some View {
        Menu("Capture/Record") {
            Button("Capture Region") {
                captureScreen(type: .REGION)
            }.keyboardShortcut(.captureRegion)
            Button("Capture Window") {
                captureScreen(type: .WINDOW)
            }.keyboardShortcut(.captureWindow)
            ForEach(NSScreen.screens.indices, id: \.self) { index in
                let screen = NSScreen.screens[index]
                let screenName = screen.localizedName
                Button("Capture \(screenName)") {
                    captureScreen(type: .SCREEN, display: index + 1)
                }.keyboardShortcut(index == 0 ? .captureScreen : .noKeybind)
            }
            Divider()
            Button("Record Region") {
            }.keyboardShortcut(.recordRegion).disabled(!isFFmpegInstalled)
            Button("Record Screen") {
            }.keyboardShortcut(.recordScreen).disabled(!isFFmpegInstalled)
        }.onAppear {
            isFFmpegInstalled = checkAppInstallation(.FFMPEG)
        }
        
        Menu("Post Media Tasks") {
            Toggle("Copy to clipboard", isOn: $copyToClipboard).toggleStyle(.checkbox)
            Toggle("Open in Finder", isOn: $openInFinder).toggleStyle(.checkbox)
            Toggle("Upload media", isOn: $uploadMedia).toggleStyle(.checkbox)
        }
        
        Picker("Upload Destination", selection: $uploadType) {
            ForEach(UploadType.allCases.filter { $0 != .CUSTOM }, id: \.self) {
                Text($0.rawValue.capitalized)
            }
            if let uploaders = savedCustomUploaders {
                if !uploaders.isEmpty {
                    // doesn't work :(
//                    Picker("Custom", selection: $activeCustomUploader) {
//                        ForEach(CustomUploader.allCases.map({ $0.id }), id: \.self) { uploader in
//                            Text(CustomUploader.allCases.first(where: { $0.id == activeCustomUploader })!.name)
//                        }
//                    }
//                    .onChange(of: activeCustomUploader) { newValue in
//                        if newValue != nil {
//                            uploadType = .CUSTOM
//                        }
//                    }
                    
                    Menu("Custom") {
                        if activeCustomUploader != nil {
                            Section("Currently Active") {
                                Button(CustomUploader.allCases.first(where: { $0.id == activeCustomUploader })!.name) {
                                    activeCustomUploader = nil
                                    uploadType = .IMGUR
                                }
                            }
                            Divider()
                        }
                        
                        ForEach(uploaders.sorted(by: { $0.name < $1.name })) { uploader in
                            if uploader.id != activeCustomUploader {
                                Button(uploader.name) {
                                    activeCustomUploader = uploader.id
                                    uploadType = .CUSTOM
                                }
                            }
                        }
                    }
                }
            }
        }
        .pickerStyle(MenuPickerStyle())
        
        Button("Settings") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }.keyboardShortcut("s")
        
        Divider()
        
        Button("About ishare") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            fetchContributors { contributors in
                if let contributors = contributors {
                    var credits = "isharemac.app\n\nContributors: "
                    
                    for (index, contributor) in contributors.enumerated() {
                        if index == contributors.count - 1 {
                            credits += contributor.login
                        } else {
                            credits += "\(contributor.login), "
                        }
                    }
                    
                    let creditsAttributedString = NSAttributedString(string: credits, attributes: [
                        NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
                    ])
                    
                    var options: [NSApplication.AboutPanelOptionKey: Any] = [
                        NSApplication.AboutPanelOptionKey.credits: creditsAttributedString,
                        NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© \(Calendar.current.component(.year, from: Date())) ADRIAN CASTRO"
                    ]
                    
                    NSApplication.shared.orderFrontStandardAboutPanel(options: options)
                } else {
                    print("Failed to fetch contributors")
                }
            }
        }
        .keyboardShortcut("a")
        
        
        Button("Check for Updates") {
            selfUpdate()
        }.keyboardShortcut("u")
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}
