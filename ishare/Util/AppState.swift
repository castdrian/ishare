//
//  AppState.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults
import KeyboardShortcuts

@MainActor
final class AppState: ObservableObject {
    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleMainMenu) {
            // TODO: show main menu on keybind
        }
        KeyboardShortcuts.onKeyUp(for: .captureRegion) {
            let options = CaptureOptions(type: CaptureType.RegionImage, ext: FileType.PNG);            captureScreen(options: options)
        }
        KeyboardShortcuts.onKeyUp(for: .captureWindow) {
            let options = CaptureOptions(type: CaptureType.WindowImage, ext: FileType.PNG);            captureScreen(options: options)
        }
        KeyboardShortcuts.onKeyUp(for: .captureScreen) {
            let options = CaptureOptions(type: CaptureType.ScreenImage, ext: FileType.PNG);            captureScreen(options: options)
        }
        KeyboardShortcuts.onKeyUp(for: .recordRegion) {
        }
        KeyboardShortcuts.onKeyUp(for: .recordScreen) {
        }
    }
}
