//
//  ishareApp.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import SwiftUI

@main
struct ishareApp: App {
    var body: some Scene {
        MenuBarExtra("ishare", systemImage: "photo.on.rectangle.angled") {
            Menu("Capture") {
            }
            Menu("Upload") {}
            Menu("Destination") {}
            Button("Settings") {}.keyboardShortcut("s")
            Divider()
            Button("About") {}.keyboardShortcut("a")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
    }
}
