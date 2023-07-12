//
//  AppState.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import KeyboardShortcuts

@MainActor
final class AppState: ObservableObject {
    @State private var copyToClipboard: Bool = true
    @State private var openInFinder: Bool = false
    @State private var uploadMedia: Bool = false

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleMainMenu) {
            // TODO: show main menu on keybind
        }
        KeyboardShortcuts.onKeyUp(for: .captureRegion) {
            let options = CaptureOptions(filePath: nil, type: CaptureType.RegionImage, ext: FileType.PNG, saveFileToClipboard: self.copyToClipboard, showInFinder: self.openInFinder)
            captureScreen(options: options)
        }
        KeyboardShortcuts.onKeyUp(for: .captureWindow) {
            let options = CaptureOptions(filePath: nil, type: CaptureType.WindowImage, ext: FileType.PNG, saveFileToClipboard: self.copyToClipboard, showInFinder: self.openInFinder)
            captureScreen(options: options)
        }
        KeyboardShortcuts.onKeyUp(for: .captureScreen) {
            let options = CaptureOptions(filePath: nil, type: CaptureType.ScreenImage, ext: FileType.PNG, saveFileToClipboard: self.copyToClipboard, showInFinder: self.openInFinder)
            captureScreen(options: options)
        }
        KeyboardShortcuts.onKeyUp(for: .recordRegion) {
        }
        KeyboardShortcuts.onKeyUp(for: .recordScreen) {
        }
    }
}
