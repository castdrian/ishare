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
        // Regular shortcuts
        KeyboardShortcuts.onKeyUp(for: .captureRegion) {
            NSLog("Capture region shortcut triggered")
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
            let screenRecorder = AppDelegate.shared.screenRecorder
            if screenRecorder.isRunning {
                let pickerManager = ContentSharingPickerManager.shared
                pickerManager.deactivatePicker()
                AppDelegate.shared.stopRecording()
            } else {
                recordScreen()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .recordGif) {
            let screenRecorder = AppDelegate.shared.screenRecorder
            if screenRecorder.isRunning {
                let pickerManager = ContentSharingPickerManager.shared
                pickerManager.deactivatePicker()
                AppDelegate.shared.stopRecording()
            } else {
                recordScreen(gif: true)
            }
        }

        // Force upload shortcuts
        KeyboardShortcuts.onKeyUp(for: .captureRegionForceUpload) {
            NSLog("Force upload capture region shortcut triggered")
            Task { @MainActor in
                Defaults[.uploadMedia] = true
                await captureScreen(type: .REGION)
                Defaults[.uploadMedia] = false
            }
        }

        KeyboardShortcuts.onKeyUp(for: .captureWindowForceUpload) {
            Task { @MainActor in
                Defaults[.uploadMedia] = true
                await captureScreen(type: .WINDOW)
                Defaults[.uploadMedia] = false
            }
        }

        KeyboardShortcuts.onKeyUp(for: .captureScreenForceUpload) {
            Task { @MainActor in
                Defaults[.uploadMedia] = true
                await captureScreen(type: .SCREEN)
                Defaults[.uploadMedia] = false
            }
        }

        KeyboardShortcuts.onKeyUp(for: .recordScreenForceUpload) {
            let screenRecorder = AppDelegate.shared.screenRecorder
            if screenRecorder.isRunning {
                let pickerManager = ContentSharingPickerManager.shared
                pickerManager.deactivatePicker()
                AppDelegate.shared.stopRecording()
            } else {
                Defaults[.uploadMedia] = true
                recordScreen()
                Defaults[.uploadMedia] = false
            }
        }

        KeyboardShortcuts.onKeyUp(for: .recordGifForceUpload) {
            let screenRecorder = AppDelegate.shared.screenRecorder
            if screenRecorder.isRunning {
                let pickerManager = ContentSharingPickerManager.shared
                pickerManager.deactivatePicker()
                AppDelegate.shared.stopRecording()
            } else {
                Defaults[.uploadMedia] = true
                recordScreen(gif: true)
                Defaults[.uploadMedia] = false
            }
        }
    }
}
