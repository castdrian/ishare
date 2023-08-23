//
//  App.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import SwiftUI
import Defaults
import Sparkle
import MenuBarExtraAccess

@main
struct ishare: App {
    @Default(.menuBarIcon) var menubarIcon
    @Default(.showMainMenu) var showMainMenu
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor private var appDelegate : AppDelegate
    
    var body: some Scene {
        MenuBarExtra() {
            MainMenuView()
        }
    label: {
        switch menubarIcon {
            case .DEFAULT: Image(nsImage: GlyphIcon)
            case .APPICON: Image(nsImage: AppIcon)
            case .SYSTEM: Image(systemName: "photo.on.rectangle.angled")
        }
    }
    .menuBarExtraAccess(isPresented: $showMainMenu)
        Settings {
            SettingsMenuView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    static private(set) var shared: AppDelegate! = nil
    var isIconShown = false
    var recordGif = false
    var statusBarItem: NSStatusItem!
    var screenRecorder: ScreenRecorder!
    var updaterController: SPUStandardUpdaterController!
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.count == 1 {
            importIscu(urls.first!)
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        Task {
            screenRecorder = ScreenRecorder()
        }
        
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
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
        Task {
            await screenRecorder.stop { [self] result in
                switch result {
                case .success(let url):
                    print("Recording stopped successfully. URL: \(url)")
                    postRecordingTasks(url, recordGif)
                case .failure(let error):
                    print("Error while stopping recording: \(error.localizedDescription)")
                }
            }
        }
    }
}
