//
//  MenuBarScene.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
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

struct MenuBarScene: Scene {
    @State private var selectedDestination: Destination = .IMGUR

    var body: some Scene {
        MenuBarExtra("ishare", systemImage: "photo.on.rectangle.angled") {
            Menu("Capture") {
                Button("Region Capture") {}
                Button("Window Capture") {
                  //  captureScreen(options: CaptureOptions(filePath: nil, type: CaptureType.WindowImage, ext: FileType.PNG, saveFileToClipboard: true))
                }
                Button("Screen Capture") {}
                Button("Record Region") {}.disabled(true)
                Button("Record Screen") {}.disabled(true)
            }

            Picker("Destination", selection: $selectedDestination) {
                ForEach(Destination.allCases, id: \.self) {
                    Text($0.rawValue.capitalized)
                }
            }.pickerStyle(MenuPickerStyle())
            
            Button("Settings") {}.keyboardShortcut("s").disabled(true)
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
}
