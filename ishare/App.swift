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
        if #available(macOS 13.0, *) {
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
}

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    @Default(.menuBarIcon) var menubarIcon
    static private(set) var shared: AppDelegate! = nil
    var isIconShown = false
    var recordGif = false
    var statusBarItem: NSStatusItem!
    var legacyMainMenuStatusBarItem: NSStatusItem!
    var popover: NSPopover!
        
    var _screenRecorder: Any? = nil

    @available(macOS 13.0, *)
    var screenRecorder: ScreenRecorder {
        get {
            return _screenRecorder as! ScreenRecorder
        }
        set {
            _screenRecorder = newValue
        }
    }

    var updaterController: SPUStandardUpdaterController!
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.count == 1 {
            importIscu(urls.first!)
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        if #available(macOS 13.0, *) {
            Task {
                screenRecorder = ScreenRecorder()
            }
        } else {
            legacyMainMenuStatusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            
            let mainMenuView = MainMenuView()
            
            popover = NSPopover()
            popover.contentSize = NSSize(width: 250, height: 350)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(rootView: mainMenuView)
            
            if let button = legacyMainMenuStatusBarItem.button {
                button.action = #selector(showPopover(_:))
                button.image = switch menubarIcon {
                    case .DEFAULT: GlyphIcon
                    case .APPICON: AppIcon
                    case .SYSTEM: NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Main Menu Icon")
                }
            }
        }
                
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }
    
    @objc func showPopover(_ sender: AnyObject?) {
        if let button = self.legacyMainMenuStatusBarItem.button
        {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    @available(macOS 13.0, *)
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
    
    @available(macOS 13.0, *)
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

