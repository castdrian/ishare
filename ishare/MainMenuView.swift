//
//  MainMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI

enum PostCaptureTasks: String, CaseIterable, Identifiable {
    case COPY_TO_CLIPBOARD, OPEN_CAPTURE_FOLDER, UPLOAD_CAPTURE
    var id: Self { self }
}

enum Destination: String, CaseIterable, Identifiable {
    case IMGUR, CUSTOM
    var id: Self { self }
}

struct MainMenuView: View {
    @State private var selectedDestination: Destination = .IMGUR
    @State private var togglebool: Bool = false
    
    var body: some View {
        Menu("Capture") {
            Button("Capture Region") {
                captureScreen(options: CaptureOptions(filePath: nil, type: CaptureType.RegionImage, ext: FileType.PNG, saveFileToClipboard: true, showInFinder: false))
            }
            Button("Capture Window") {
                captureScreen(options: CaptureOptions(filePath: nil, type: CaptureType.WindowImage, ext: FileType.PNG, saveFileToClipboard: true, showInFinder: false))
            }
            Button("Capture Screen") {
                captureScreen(options: CaptureOptions(filePath: nil, type: CaptureType.ScreenImage, ext: FileType.PNG, saveFileToClipboard: true, showInFinder: false))
            }
            Divider()
            Button("Record Region") {}
            Button("Record Window") {}
            Button("Record Screen") {}
        }
        
        Menu("Post Capture Tasks") {
            Toggle("Copy to clipboard", isOn: $togglebool).toggleStyle(.checkbox)
            Toggle("Open in Finder", isOn: $togglebool).toggleStyle(.checkbox)
            Toggle("Upload capture", isOn: $togglebool).toggleStyle(.checkbox)
        }

        Picker("Destination", selection: $selectedDestination) {
            ForEach(Destination.allCases, id: \.self) {
                Text($0.rawValue.capitalized)
            }
            Divider()
            Button("Custom Uploader Settings") {
                
            }
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
