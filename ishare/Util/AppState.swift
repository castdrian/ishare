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
    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleMainMenu) {
            // TODO: show main menu on keybind
        }
    }
}
