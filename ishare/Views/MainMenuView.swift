//
//  MainMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI

enum PostCaptureTasks: String, CaseIterable, Identifiable {
    case COPY_TO_CLIPBOARD, OPEN_CAPTURE_FOLDER, UPLOAD_MEDIA
    var id: Self { self }
}

enum Destination: String, CaseIterable, Identifiable {
    case IMGUR, CUSTOM
    var id: Self { self }
}

struct MainMenuView: View {
    @State private var selectedDestination: Destination = .IMGUR
    @State private var copyToClipboard: Bool = true
    @State private var openInFinder: Bool = false
    @State private var uploadMedia: Bool = false
    
    var body: some View {
        Menu("Capture/Record") {
            Button("Capture Region") {
                let options = CaptureOptions(filePath: nil, type: CaptureType.RegionImage, ext: FileType.PNG, saveFileToClipboard: copyToClipboard, showInFinder: openInFinder)
                captureScreen(options: options)
            }
            Button("Capture Window") {
                let options = CaptureOptions(filePath: nil, type: CaptureType.WindowImage, ext: FileType.PNG, saveFileToClipboard: copyToClipboard, showInFinder: openInFinder)
                captureScreen(options: options)
            }
            Button("Capture Screen") {
                let options = CaptureOptions(filePath: nil, type: CaptureType.ScreenImage, ext: FileType.PNG, saveFileToClipboard: copyToClipboard, showInFinder: openInFinder)
                captureScreen(options: options)
            }
            Divider()
            Button("Record Region") {
            }.disabled(true)
            Button("Record Screen") {
            }.disabled(true)
        }
        
        Menu("Post Media Tasks") {
            Toggle("Copy to clipboard", isOn: $copyToClipboard).toggleStyle(.checkbox)
            Toggle("Open in Finder", isOn: $openInFinder).toggleStyle(.checkbox)
            Toggle("Upload capture", isOn: $uploadMedia).toggleStyle(.checkbox)
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
