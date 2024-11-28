//
//  AppState.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    
    @Default(.showMainMenu) var showMainMenu
    @Default(.uploadHistory) var uploadHistory

    init() {
        setupKeyboardShortcuts()
    }
    
    func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .toggleMainMenu) { [weak self] in
            self?.showMainMenu = true
        }
        
        KeyboardShortcuts.onKeyUp(for: .openHistoryWindow) { [weak self] in
            guard let self = self else { return }
            openHistoryWindow(uploadHistory: self.uploadHistory)
        }
        
        KeyboardShortcuts.onKeyUp(for: .captureRegion) {
            Task { @MainActor in
                await captureScreen(type: .REGION)
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .captureWindow) {
            Task { @MainActor in
                await captureScreen(type: .WINDOW)
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .captureScreen) {
            Task { @MainActor in
                await captureScreen(type: .SCREEN)
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .recordScreen) {
            recordScreen()
        }
        
        KeyboardShortcuts.onKeyUp(for: .recordGif) {
            recordScreen(gif: true)
        }
    }
}
