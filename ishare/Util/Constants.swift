//
//  Constants.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults
@testable import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleMainMenu = Self("toggleMainMenu", default: .init(.s, modifiers: [.option, .command]))
    static let captureRegion = Self("captureRegion", default: .init(.p, modifiers: [.option, .command]))
    static let captureWindow = Self("captureWindow", default: .init(.p, modifiers: [.control,.option]))
    static let captureScreen = Self("captureScreen", default: .init(.x, modifiers: [.option, .command]))
    static let recordRegion = Self("recordRegion", default: .init(.z, modifiers: [.option, .command]))
    static let recordScreen = Self("recordScreen", default: .init(.z, modifiers: [.control, .option,]))
}

extension Defaults.Keys {
    static let copyToClipboard = Key<Bool>("copyToClipboard", default: true)
    static let openInFinder = Key<Bool>("openInFinder", default: false)
    static let uploadMedia = Key<Bool>("uploadMedia", default: false)
}

extension KeyboardShortcuts.Shortcut {
    var swiftUI: SwiftUI.KeyboardShortcut? {
        guard let key = keyEquivalent.first else { return nil }
        return .init(.init(key), modifiers: modifiers.swiftUI)
    }
}

extension NSEvent.ModifierFlags {
    var swiftUI: SwiftUI.EventModifiers {
        var modifiers: SwiftUI.EventModifiers = []
        if contains(.shift) {
            modifiers.insert(.shift)
        }
        if contains(.command) {
            modifiers.insert(.command)
        }
        if contains(.capsLock) {
            modifiers.insert(.capsLock)
        }
        if contains(.function) {
            modifiers.insert(.function)
        }
        if contains(.option) {
            modifiers.insert(.option)
        }
        if contains(.control) {
            modifiers.insert(.control)
        }
        return modifiers
    }
}

extension View {
    @ViewBuilder
    /// Assigns the global keyboard shortcut to the modified control.
    ///
    /// Only assigns a keyboard shortcut, if one was defined (or it has a default shortcut).
    ///
    /// - Parameter shortcut: Strongly-typed name of the shortcut
    public func keyboardShortcut(_ shortcut: KeyboardShortcuts.Name) -> some View {
        if let shortcut = (shortcut.shortcut ?? shortcut.defaultShortcut)?.swiftUI {
            self.keyboardShortcut(shortcut)
        } else {
            self
        }
    }
}

func isFFmpegInstalled() -> Bool {
    let fileManager = FileManager.default
    let ffmpegPath = "/usr/local/bin/ffmpeg"

    return fileManager.fileExists(atPath: ffmpegPath)
}
