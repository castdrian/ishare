//
//  App.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import Defaults
import MenuBarExtraAccess
import SwiftUI

#if canImport(Sparkle)
    import Sparkle
#endif

@main
struct ishare: App {
    @Default(.menuBarIcon) var menubarIcon
    @Default(.showMainMenu) var showMainMenu
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra {
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

#if GITHUB_RELEASE
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    private static let sharedInstance = AppDelegate()
    static var shared: AppDelegate { sharedInstance }
    
    var recordGif = false
    let screenRecorder = ScreenRecorder()
    var updaterController: SPUStandardUpdaterController!

    func application(_: NSApplication, open urls: [URL]) {
        if urls.first!.isFileURL {
            NSLog("Attempting to import ISCU file from: %@", urls.first!.path)
            importIscu(urls.first!)
        }

        if let url = urls.first {
            NSLog("Processing URL scheme: %@", url.absoluteString)
            let path = url.host
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

            if path == "upload" {
                if let fileItem = queryItems?.first(where: { $0.name == "file" }) {
                    if let encodedFileURLString = fileItem.value, 
                       let decodedFileURLString = encodedFileURLString.removingPercentEncoding, 
                       let fileURL = URL(string: decodedFileURLString) {
                        NSLog("Processing upload request for file: %@", fileURL.absoluteString)

                        @Default(.uploadType) var uploadType
                        NSLog("Using upload type: %@", String(describing: uploadType))
                        let localFileURL = fileURL

                        uploadFile(fileURL: fileURL, uploadType: uploadType) {
                            Task { @MainActor in
                                NSLog("Upload completed, showing toast notification")
                                showToast(fileURL: localFileURL) {
                                    NSSound.beep()
                                }
                            }
                        }
                    } else {
                        NSLog("Error: Failed to process file URL from query parameters")
                    }
                }
            }
        }
    }

    func applicationDidFinishLaunching(_: Notification) {
        NSLog("Application finished launching")
        
        Task {
            NSLog("Initializing screen recorder")
            screenRecorder = ScreenRecorder()
        }

        #if GITHUB_RELEASE
        NSLog("Initializing updater controller for GitHub release")
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        #endif
    }

    @MainActor
    func stopRecording() {
        let wasRecordingGif = recordGif
        let recorder = screenRecorder
        
        Task {
            recorder?.stop { result in
                Task { @MainActor in
                    switch result {
                    case let .success(url):
                        print("Recording stopped successfully. URL: \(url)")
                        postRecordingTasks(url, wasRecordingGif)
                    case let .failure(error):
                        print("Error while stopping recording: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
#else
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private static let sharedInstance = AppDelegate()
    static var shared: AppDelegate { sharedInstance }
    
    var recordGif = false
    var screenRecorder = ScreenRecorder()

    func application(_: NSApplication, open urls: [URL]) {
        if urls.first!.isFileURL {
            importIscu(urls.first!)
        }

        if let url = urls.first {
            let path = url.host
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

            if path == "upload" {
                if let fileItem = queryItems?.first(where: { $0.name == "file" }) {
                    if let encodedFileURLString = fileItem.value, let decodedFileURLString = encodedFileURLString.removingPercentEncoding, let fileURL = URL(string: decodedFileURLString) {
                        print("Received file URL: \(fileURL.absoluteString)")

                        @Default(.uploadType) var uploadType
                        let localFileURL = fileURL

                        uploadFile(fileURL: fileURL, uploadType: uploadType) {
                            Task { @MainActor in
                                showToast(fileURL: localFileURL) {
                                    NSSound.beep()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func applicationDidFinishLaunching(_: Notification) {
        NSLog("Application finished launching")
        
        Task {
            screenRecorder = ScreenRecorder()
        }
    }

    @MainActor
    func stopRecording() {
        let wasRecordingGif = recordGif
        let recorder = screenRecorder
        
        Task {
            recorder.stop { result in
                Task { @MainActor in
                    switch result {
                    case let .success(url):
                        print("Recording stopped successfully. URL: \(url)")
                        postRecordingTasks(url, wasRecordingGif)
                    case let .failure(error):
                        print("Error while stopping recording: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
#endif
