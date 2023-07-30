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

enum RecordingType {
    case SCREEN
    case WINDOW

    func getCaptureType() -> ScreenRecorder.CaptureType {
        switch self {
        case .SCREEN:
            return ScreenRecorder.CaptureType.display
        case .WINDOW:
            return ScreenRecorder.CaptureType.window
        }
    }
}

@MainActor
func recordScreen(type: RecordingType, display: SCDisplay) {
    let screenRecorder = AppDelegate.shared.screenRecorder
    screenRecorder?.captureType = ScreenRecorder.CaptureType.display
    screenRecorder?.selectedDisplay = display
    
    let popupWindow = showCapturePreviewPopup(capturePreview: screenRecorder!.capturePreview, display: display)
    
    Task {
        if ((await screenRecorder?.canRecord) != nil) {
            await screenRecorder?.start()
            // Show the popup and store the window reference

            // To dismiss the popup programmatically, call the close() method on the window reference
            //popupWindow.close()

        } else {
            BezelNotification.show(messageText: "Missing permission", icon: ToastIcon)
        }
    }

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
//
//        deleteScreenRecordings()
//    }
}

//func recordingTask(path: String, type: RecordingType, display: Int = 1, completion: @escaping () -> Void) {
//    AppDelegate.shared.toggleIcon(AppDelegate.shared as AnyObject)
//
//    @Default(.captureBinary) var captureBinary
//
//    let task = Process()
//    task.launchPath = captureBinary
//    task.arguments = type == RecordingType.SCREEN ? [type.rawValue, "-D", "\(display)", path] : [type.rawValue, path]
//
//    AppDelegate.shared.recordingTask = task
//
//    DispatchQueue.global(qos: .background).async {
//        task.launch()
//        task.waitUntilExit()
//
//        DispatchQueue.main.async {
//            AppDelegate.shared.recordingTask = nil
//            completion()
//        }
//    }
//}
//
//func deleteScreenRecordings() {
//    let screenRecordingsPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/ScreenRecordings")
//
//    do {
//        try FileManager.default.removeItem(at: screenRecordingsPath)
//    } catch {
//        print("Error deleting the ScreenRecordings folder: \(error)")
//    }
//}
