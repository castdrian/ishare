//
//  App.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import SwiftUI
import KeyboardShortcuts

@main
struct ishare: App {
    @StateObject private var appState = AppState()
    var body: some Scene {
        MenuBarExtra("ishare", systemImage: "photo.on.rectangle.angled") {
            MainMenuView()
        }
        
        Settings {
            SettingsMenuView()
        }
    }
}
