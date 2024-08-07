//
//  AppState.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

final class AppState: ObservableObject {
    @Default(.showMainMenu) var showMainMenu
    @Default(.uploadHistory) var uploadHistory

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleMainMenu) { [self] in
            showMainMenu = true
        }
        KeyboardShortcuts.onKeyUp(for: .openHistoryWindow) { [self] in
            openHistoryWindow(uploadHistory: uploadHistory)
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
        KeyboardShortcuts.onKeyUp(for: .recordScreen) {
            recordScreen()
        }
        KeyboardShortcuts.onKeyUp(for: .recordGif) {
            recordScreen(gif: true)
        }
    }
}
