//
//  ScreenCapture.swift
//  ishare
//
//  Created by Adrian Castro on 11.07.23.
//

import Foundation
import AppKit

enum CaptureType: String {
    case ScreenImage = ""
    case WindowImage = "-w"
    case RegionImage = "-s"
    // case ScreenVideo = "-v"
    // case RegionVideo = "-vs"
}

enum FileType: String {
    case PNG = ".png"
    case MOV = ".mov"
}

struct CaptureOptions {
    let filePath: String?
    let type: CaptureType
    let ext: FileType
    let saveFileToClipboard: Bool
    let showInFinder: Bool
}

func captureScreen(options: CaptureOptions) -> Void {
    let timestamp = Int(Date().timeIntervalSince1970)
    let uniqueFilename = "ishare-\(timestamp)"
    
    var path = "\(options.filePath ?? "~/Pictures/")\(uniqueFilename)\(options.ext.rawValue)"
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
    
    if options.saveFileToClipboard {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
            
        pasteboard.setString(fileURL.absoluteString, forType: .fileURL)
    }
    
    if options.showInFinder {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    showToast(fileURL: fileURL)
}
