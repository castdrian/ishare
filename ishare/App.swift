//
//  App.swift
//  ishare
//
//  Created by Adrian Castro on 10.07.23.
//

import Defaults
import MenuBarExtraAccess
import SwiftUI

#if GITHUB_RELEASE
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
    class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
        private(set) static var shared: AppDelegate! = nil
        var recordGif = false
        var screenRecorder: ScreenRecorder!
        var updaterController: SPUStandardUpdaterController!

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

                            uploadFile(fileURL: fileURL, uploadType: uploadType) {
                                showToast(fileURL: fileURL) {
                                    NSSound.beep()
                                }
                            }
                        }
                    }
                }
            }
        }

        func applicationDidFinishLaunching(_: Notification) {
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
                    case let .success(url):
                        print("Recording stopped successfully. URL: \(url)")
                        postRecordingTasks(url, recordGif)
                    case let .failure(error):
                        print("Error while stopping recording: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
#else

    class AppDelegate: NSObject, NSApplicationDelegate {
        private(set) static var shared: AppDelegate! = nil
        var recordGif = false
        var screenRecorder: ScreenRecorder!

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

                            uploadFile(fileURL: fileURL, uploadType: uploadType) {
                                showToast(fileURL: fileURL) {
                                    NSSound.beep()
                                }
                            }
                        }
                    }
                }
            }
        }

        func applicationDidFinishLaunching(_: Notification) {
            AppDelegate.shared = self

            Task {
                screenRecorder = ScreenRecorder()
            }
        }

        func stopRecording() {
            Task {
                await screenRecorder.stop { [self] result in
                    switch result {
                    case let .success(url):
                        print("Recording stopped successfully. URL: \(url)")
                        postRecordingTasks(url, recordGif)
                    case let .failure(error):
                        print("Error while stopping recording: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
#endif
