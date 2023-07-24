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

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate! = nil
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.count == 1 {
            importIscu(urls.first!)
        }
    }
    
    lazy var statusBarItem: NSStatusItem = {
        return NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    }()
    
    var isIconShown = false
    var recordingTask: Process?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        if let button = statusBarItem.button {
            button.action = #selector(toggleIcon)
        }
    }
    
    @objc func toggleIcon(_ sender: AnyObject) {
        isIconShown.toggle()
        
        if isIconShown {
            statusBarItem.button?.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: "Stop Icon")
        } else {
            statusBarItem.button?.image = nil
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
