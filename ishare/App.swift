//
//  App.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import SwiftUI
import Defaults
import FinderSync

@main
struct ishare: App {
    @Default(.menuBarAppIcon) var menuBarAppIcon
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor private var appDeletate : AppDelegate
    
    var body: some Scene {
        MenuBarExtra() {
            MainMenuView()
        }
    label: {
        menuBarAppIcon ? Image(nsImage: AppIcon) : Image(systemName: "photo.on.rectangle.angled")
    }
        
        Settings {
            SettingsMenuView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.count == 1 {
            importIscu(urls.first!)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Show extensions, if ishare is not approved
        if !FIFinderSyncController.isExtensionEnabled {
            FIFinderSyncController.showExtensionManagementInterface()
        }
    }
}
