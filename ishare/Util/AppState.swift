//
//  AppState.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import Defaults
import KeyboardShortcuts
import SwiftUI
import UniformTypeIdentifiers

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

		KeyboardShortcuts.onKeyUp(for: .openMostRecentItem) {
			guard let mostRecentItem = AppState.shared.uploadHistory.last,
				let fileUrlString = mostRecentItem.fileUrl,
				let fileURL = URL(string: fileUrlString)
			else {
				return
			}
			NSWorkspace.shared.open(fileURL)
		}

		KeyboardShortcuts.onKeyUp(for: .uploadPasteBoardItem) {
			let pasteboard = NSPasteboard.general
			
			// First check for media file URL
			if let mediaURL = pasteboard.mediaURL {
				uploadFile(fileURL: mediaURL, uploadType: Defaults[.uploadType]) {
					Task { @MainActor in
						showToast(fileURL: mediaURL) {
							NSSound.beep()
						}
					}
				}
				return
			}
			
			// Then check for raw image data
			if let image = pasteboard.imageFromData,
			   let tiffData = image.tiffRepresentation,
			   let bitmapImage = NSBitmapImageRep(data: tiffData),
			   let data = bitmapImage.representation(using: .png, properties: [:]) {
				
				let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("pasteboard_image.png")
				try? data.write(to: tempURL)
				
				uploadFile(fileURL: tempURL, uploadType: Defaults[.uploadType]) {
					Task { @MainActor in
						showToast(fileURL: tempURL) {
							NSSound.beep()
							try? FileManager.default.removeItem(at: tempURL)
						}
					}
				 }
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
