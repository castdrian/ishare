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
                Button("Screen Capture") {}
                Button("Record Region") {}
                Button("Record Screen") {}
            }
            Menu("Upload") {}
            Menu("History") {}

            Picker("Destination", selection: $selectedDestination) {
                Text("Imgur")
                Text("Custom")
            }.pickerStyle(MenuPickerStyle())
            
            Button("Settings") {}.keyboardShortcut("s")
            Divider()
            Button("About") {}.keyboardShortcut("a")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
    }
}
