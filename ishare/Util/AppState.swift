//
//  AppState.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults
import KeyboardShortcuts

final class AppState: ObservableObject {
    @Default(.showMainMenu) var showMainMenu

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleMainMenu) {
            self.showMainMenu = true
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
        KeyboardShortcuts.onKeyUp(for: .recordWindow) {
        }
        KeyboardShortcuts.onKeyUp(for: .recordScreen) {
            recordScreen()
        }
    }
}
