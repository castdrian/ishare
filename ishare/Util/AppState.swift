//
//  AppState.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults
import KeyboardShortcuts

struct ContextMenuView: View {
    var body: some View {
        VStack {
            Button("Item 1") {
                handleMenuItemAction("Item 1")
            }
            Button("Item 2") {
                handleMenuItemAction("Item 2")
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    func handleMenuItemAction(_ item: String) {
        // Handle the menu item action
        print("Selected item: \(item)")
    }
}

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
        }
    }
}
