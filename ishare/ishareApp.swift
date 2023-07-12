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
            MainMenuView()
        }
        
        Settings {
            SettingsMenuView()
        }
    }
}
