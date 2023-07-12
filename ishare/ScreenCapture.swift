//
//  ScreenCapture.swift
//  ishare
//
//  Created by Adrian Castro on 11.07.23.
//

import Foundation
import AppKit
import AlertToast

enum CaptureType: String {
    case ScreenImage = ""
    case WindowImage = "-w"
    case RegionImage = "-s"
    case ScreenVideo = "-v"
    case WindowVideo = "-vw"
    case RegionVideo = "-vs"
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

func captureScreen(options: CaptureOptions) -> (success: Bool, fileURL: URL?) {
    let timestamp = Int(Date().timeIntervalSince1970)
    let uniqueFilename = "ishare-\(timestamp)"
    
    var path = "\(options.filePath ?? "~/Pictures/")\(uniqueFilename)\(options.ext.rawValue)"
    path = NSString(string: path).expandingTildeInPath
    
    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = [options.type.rawValue, path]
    task.launch()
    task.waitUntilExit()
    
    let status = task.terminationStatus
    let fileURL = URL(fileURLWithPath: path)
    
    if !FileManager.default.fileExists(atPath: fileURL.path) {
        return (false, nil)
    }
    
    if options.saveFileToClipboard {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
            
        pasteboard.setString(fileURL.absoluteString, forType: .fileURL)
    }
    
    if options.showInFinder {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
        
    // AlertToast(displayMode: .banner(.slide), type: .regular, title: "Captured!")
    
    return (status == 0, fileURL)
}
