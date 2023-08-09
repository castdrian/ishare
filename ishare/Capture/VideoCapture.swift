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
    @Default(.openInFinder) var openInFinder
    @Default(.recordingPath) var recordingPath
    @Default(.recordingFileName) var fileName
    @Default(.recordMP4) var recordMP4
    
    let timestamp = Int(Date().timeIntervalSince1970)
    let uniqueFilename = "\(fileName)-\(timestamp)"
    
    var path = "\(recordingPath)\(uniqueFilename).\(recordMP4 ? "mp4" : "mov")"
    path = NSString(string: path).expandingTildeInPath
    
    let fileURL = URL(fileURLWithPath: path)
    
    let screenRecorder = AppDelegate.shared.screenRecorder
    screenRecorder?.isAudioCaptureEnabled = recordAudio
    
    if let display = display {
        screenRecorder?.captureType = ScreenRecorder.CaptureType.display
        screenRecorder?.selectedDisplay = display
        
        if showPreview {
            showCapturePreviewPopup(capturePreview: screenRecorder!.capturePreview, screenRecorder: screenRecorder!, display: display)
        }
        
    } else if let window = window {
        screenRecorder?.captureType = ScreenRecorder.CaptureType.window
        screenRecorder?.selectedWindow = window
        
        if showPreview {
            showCapturePreviewPopup(capturePreview: screenRecorder!.capturePreview, screenRecorder: screenRecorder!, window: window)
        }
        
    } else if (display == nil) && (window == nil) {
        Task {
            do {
                let availableContent = try await refreshAvailableContent()
                screenRecorder?.selectedDisplay = availableContent.displays.first
                
                if showPreview {
                    showCapturePreviewPopup(capturePreview: screenRecorder!.capturePreview, screenRecorder: screenRecorder!, display: screenRecorder?.availableDisplays.first)
                }
            } catch {
                print("Error refreshing content: \(error)")
            }
        }
    }
    
    if !showPreview {
        AppDelegate.shared.toggleIcon(AppDelegate.shared as AnyObject)
    }
    
    Task {
        if ((await screenRecorder?.canRecord) != nil) {
            await screenRecorder?.start(fileURL)
        } else {
            BezelNotification.show(messageText: "Missing permission", icon: ToastIcon)
        }
    }
}

func postRecordingTasks(_ fileURL: URL) {
    @Default(.copyToClipboard) var copyToClipboard
    @Default(.openInFinder) var openInFinder
    @Default(.recordingPath) var recordingPath
    @Default(.recordingFileName) var fileName
    @Default(.uploadType) var uploadType
    @Default(.uploadMedia) var uploadMedia
    @Default(.saveToDisk) var saveToDisk
    
    if !FileManager.default.fileExists(atPath: fileURL.path) {
        return
    }
    
    if copyToClipboard {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        pasteboard.setString(fileURL.absoluteString, forType: .fileURL)
    }
    
    if openInFinder {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    if uploadMedia {
        uploadFile(fileURL: fileURL, uploadType: uploadType) {
            showToast(fileURL: fileURL) {
                NSSound.beep()
                
                if !saveToDisk {
                    do {
                        try FileManager.default.removeItem(at: fileURL)
                    } catch {
                        print("Error deleting the file: \(error)")
                    }
                }
            }
        }
    } else {
        showToast(fileURL: fileURL) {
            NSSound.beep()
            
            if !saveToDisk {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("Error deleting the file: \(error)")
                }
            }
        }
    }
    shareBasedOnPreferences(fileURL)
}
