//
//  ScreenRecording.swift
//  ishare
//
//  Created by Adrian Castro on 24.07.23.
//

import BezelNotification
import Foundation
import SwiftUI
import Defaults
import AppKit
import Cocoa
import ScreenCaptureKit

@MainActor
func recordScreen(display: SCDisplay? = nil, window: SCWindow? = nil) {
    @Default(.showRecordingPreview) var showPreview
    @Default(.recordAudio) var recordAudio
    
    let screenRecorder = AppDelegate.shared.screenRecorder
    screenRecorder?.isAudioCaptureEnabled = recordAudio
    
    if let display = display {
        screenRecorder?.captureType = ScreenRecorder.CaptureType.display
        screenRecorder?.selectedDisplay = display
        
        if showPreview {
            let popupWindow = showCapturePreviewPopup(capturePreview: screenRecorder!.capturePreview, display: display)
            AppDelegate.shared.previewPopup = popupWindow
        }
    } else if let window = window {
        screenRecorder?.captureType = ScreenRecorder.CaptureType.window
        screenRecorder?.selectedWindow = window
        
        if showPreview {
            let popupWindow = showCapturePreviewPopup(capturePreview: screenRecorder!.capturePreview, window: window)
            AppDelegate.shared.previewPopup = popupWindow
        }
    } else if (display == nil) && (window == nil) {
        Task {
            do {
                let availableContent = try await refreshAvailableContent()
                screenRecorder?.selectedDisplay = availableContent.displays.first
                
                if showPreview {
                    let popupWindow = showCapturePreviewPopup(capturePreview: screenRecorder!.capturePreview, window: window)
                    AppDelegate.shared.previewPopup = popupWindow
                }
            } catch {
                print("Error refreshing content: \(error)")
            }
        }
    }
    
    AppDelegate.shared.toggleIcon(AppDelegate.shared as AnyObject)
    
    Task {
        if ((await screenRecorder?.canRecord) != nil) {
            await screenRecorder?.start()
        } else {
            BezelNotification.show(messageText: "Missing permission", icon: ToastIcon)
        }
    }
    
//    Task {
//        while (screenRecorder?.isRunning ?? false) {
//            try await Task.sleep(nanoseconds: 100)
//        }
//
//        // The recording has finished at this point, continue with the rest of the code
//        DispatchQueue.main.async {
//            print("pog recording actually stopped")
//            BezelNotification.show(messageText: "Recording finished", icon: ToastIcon)
//        }
//    }
    //    @Default(.copyToClipboard) var copyToClipboard
    //    @Default(.openInFinder) var openInFinder
    //    @Default(.recordingPath) var recordingPath
    //    @Default(.recordingFileName) var fileName
    //    @Default(.uploadType) var uploadType
    //    @Default(.uploadMedia) var uploadMedia
    //
    //    let timestamp = Int(Date().timeIntervalSince1970)
    //    let uniqueFilename = "\(fileName)-\(timestamp)"
    //
    //    var path = "\(recordingPath)\(uniqueFilename).mov"
    //    path = NSString(string: path).expandingTildeInPath
    //
    //    recordingTask(path: path, type: type, display: display) {
    //        let fileURL = URL(fileURLWithPath: path)
    //
    //        if !FileManager.default.fileExists(atPath: fileURL.path) {
    //            return
    //        }
    //
    //        if copyToClipboard {
    //            let pasteboard = NSPasteboard.general
    //            pasteboard.clearContents()
    //
    //            pasteboard.setString(fileURL.absoluteString, forType: .fileURL)
    //        }
    //
    //        if openInFinder {
    //            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    //        }
    //
    //        if uploadMedia {
    //            uploadFile(fileURL: fileURL, uploadType: uploadType) {
    //                showToast(fileURL: fileURL)
    //                NSSound.beep()
    //            }
    //        } else {
    //            showToast(fileURL: fileURL)
    //            NSSound.beep()
    //        }
    //    }
}
