//
//  App.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import SwiftUI
import Defaults
import MenuBarExtraAccess
#if NOT_APP_STORE
import Sparkle
#endif

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

#if NOT_APP_STORE
class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    static private(set) var shared: AppDelegate! = nil
    var recordGif = false
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
#else

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate! = nil
    var recordGif = false
    var screenRecorder: ScreenRecorder!
    
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
#endif
