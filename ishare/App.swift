//
//  App.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import SwiftUI
import Defaults
import Sparkle
import FinderSync

@main
struct ishare: App {
    @Default(.menuBarAppIcon) var menuBarAppIcon
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor private var appDelegate : AppDelegate
    
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

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    static private(set) var shared: AppDelegate! = nil
    var isIconShown = false
    var recordingTask: Process?
    var statusBarItem: NSStatusItem!
    var updaterController: SPUStandardUpdaterController!
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.count == 1 {
            importIscu(urls.first!)
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        updaterController.updater.checkForUpdatesInBackground()
    }
    
    @objc func toggleIcon(_ sender: AnyObject) {
        isIconShown.toggle()
        
        if isIconShown {
            statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            if let button = statusBarItem.button {
                button.action = #selector(toggleIcon)
                button.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: "Stop Icon")
            }
        } else {
            NSStatusBar.system.removeStatusItem(statusBarItem)
            statusBarItem = nil
        }
        
        if !isIconShown {
            stopRecording()
        }
    }
    
    func stopRecording() {
        recordingTask?.interrupt()
        recordingTask = nil
    }
}
