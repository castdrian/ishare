//
//  MenuBarScene.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import SwiftUI

enum Destination: String, CaseIterable, Identifiable {
    case imgur, custom
    var id: Self { self }
}

struct MenuBarScene: Scene {
    @State private var selectedDestination: Destination = .imgur

    var body: some Scene {
        MenuBarExtra("ishare", systemImage: "photo.on.rectangle.angled") {
            Menu("Capture") {
                Button("Region Capture") {}
                Button("Window Capture") {
                    captureScreen(options: CaptureOptions(filePath: nil, type: CaptureType.WindowImage, ext: FileType.PNG, saveFileToClipboard: true))
                }
                Button("Screen Capture") {}
                Button("Record Region") {}.disabled(true)
                Button("Record Screen") {}.disabled(true)
            }
            Menu("Upload") {}.disabled(true)
            Menu("History") {}.disabled(true)

            Picker("Destination", selection: $selectedDestination) {
                Text("Imgur")
                Text("Custom")
            }.pickerStyle(MenuPickerStyle())
            
            Button("Settings") {}.keyboardShortcut("s").disabled(true)
            Divider()
            Button("About") {}.keyboardShortcut("a").disabled(true)
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
    }
}
