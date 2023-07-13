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
    case ScreenImage = ""
    case WindowImage = "-w"
    case RegionImage = "-s"
}

enum FileType: String {
    case PNG = ".png"
}

struct CaptureOptions {
    let type: CaptureType
    let ext: FileType
}

func captureScreen(options: CaptureOptions) -> Void {
    @Default(.capturePath) var capturePath
    @Default(.copyToClipboard) var copyToClipboard
    @Default(.openInFinder) var openInFinder
    @Default(.uploadMedia) var uploadMedia
    
    let timestamp = Int(Date().timeIntervalSince1970)
    let uniqueFilename = "ishare-\(timestamp)"
    
    var path = "\(capturePath)\(uniqueFilename)\(options.ext.rawValue)"
    path = NSString(string: path).expandingTildeInPath
    
    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = options.type == CaptureType.ScreenImage ? [path] : [options.type.rawValue, path]
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
    
    showToast(fileURL: fileURL)
}
