//
//  App.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import SwiftUI

@main
struct ishare: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("ishare", systemImage: "photo.on.rectangle.angled") {
            MainMenuView()
        }
        
        Settings {
            SettingsMenuView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        // Handle the file open event here
        print("File opened: \(filename)")
        
        // Add your custom logic to handle the file content
        
        return true
    }
}
