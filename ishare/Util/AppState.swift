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
            // show main menu, sigh
        }
        KeyboardShortcuts.onKeyUp(for: .captureRegion) {
            captureScreen(type: .REGION)
        }
        KeyboardShortcuts.onKeyUp(for: .captureWindow) {
            captureScreen(type: .WINDOW)
        }
        KeyboardShortcuts.onKeyUp(for: .captureScreen) {
            captureScreen(type: .SCREEN)
        }
        KeyboardShortcuts.onKeyUp(for: .recordRegion) {
        }
        KeyboardShortcuts.onKeyUp(for: .recordScreen) {
            recordScreen(type: .SCREEN)
        }
    }
}
