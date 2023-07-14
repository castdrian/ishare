//
//  MainMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults

enum Destination: String, CaseIterable, Identifiable {
    case IMGUR, CUSTOM
    var id: Self { self }
}

struct MainMenuView: View {
    @State private var selectedDestination: Destination = .IMGUR
    @State private var isFFmpegInstalled: Bool = false

    @Default(.copyToClipboard) var copyToClipboard
    @Default(.openInFinder) var openInFinder
    @Default(.uploadMedia) var uploadMedia
    
    var body: some View {
        Menu("Capture/Record") {
            Button("Capture Region") {
                captureScreen(type: .REGION)
            }.keyboardShortcut(.captureRegion)
            Button("Capture Window") {
                captureScreen(type: .WINDOW)
            }.keyboardShortcut(.captureWindow)
            Button("Capture Screen") {
                captureScreen(type: .SCREEN)
            }.keyboardShortcut(.captureScreen)
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

        Picker("Upload Destination", selection: $selectedDestination) {
            ForEach(Destination.allCases, id: \.self) {
                Text($0.rawValue.capitalized)
            }
            Divider()
            Button("Custom Uploader Settings") {}.disabled(true)
        }.pickerStyle(MenuPickerStyle())
        
        Button("Settings") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }.keyboardShortcut("s")
        
        Divider()
        
        Button("About ishare") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApplication.shared.orderFrontStandardAboutPanel(
                options: [
                    NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                        string: "isharemac.app",
                        attributes: [
                            NSAttributedString.Key.font: NSFont.boldSystemFont(
                                ofSize: NSFont.smallSystemFontSize)
                        ]
                ),
                    NSApplication.AboutPanelOptionKey(
                        rawValue: "Copyright"
                    ): "© 2023 ADRIAN CASTRO"
                ]
            )
        }.keyboardShortcut("a")
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}
