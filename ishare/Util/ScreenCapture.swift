//
//  ScreenCapture.swift
//  ishare
//
//  Created by Adrian Castro on 11.07.23.
//

import Foundation
import Defaults
import AppKit

enum CaptureType: String {
    case SCREEN = "-t"
    case WINDOW = "-wt"
    case REGION = "-st"
}

enum FileType: String, CaseIterable, Identifiable, Defaults.Serializable {
    case PNG = "png"
    case JPG = "jpg"
    case PDF = "pdf"
    case TIFF = "tiff"
    case HEIC = "heic"
    var id: Self { self }
}

func captureScreen(type: CaptureType) -> Void {
    @Default(.capturePath) var capturePath
    @Default(.captureFileType) var fileType
    @Default(.copyToClipboard) var copyToClipboard
    @Default(.openInFinder) var openInFinder
    @Default(.uploadMedia) var uploadMedia
    
    let timestamp = Int(Date().timeIntervalSince1970)
    let uniqueFilename = "ishare-\(timestamp)"
    
    var path = "\(capturePath)\(uniqueFilename).\(fileType)"
    path = NSString(string: path).expandingTildeInPath
        
    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = type == CaptureType.SCREEN ? [fileType.rawValue, path] : [type.rawValue, fileType.rawValue, path]
    task.launch()
    task.waitUntilExit()
    
    let fileURL = URL(fileURLWithPath: path)
    
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
        imgurUpload(fileURL) {
            showToast(fileURL: fileURL)
            NSSound.beep()
        }
    } else {
        showToast(fileURL: fileURL)
        NSSound.beep()
    }
}
