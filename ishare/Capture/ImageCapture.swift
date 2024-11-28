//
//  ImageCapture.swift
//  ishare
//
//  Created by Adrian Castro on 11.07.23.
//

import AppKit
import Defaults
import Foundation

enum CaptureType: String {
    case SCREEN = "-t"
    case WINDOW = "-wt"
    case REGION = "-it"
}

enum FileType: String, CaseIterable, Identifiable, Defaults.Serializable {
    case PNG = "png"
    case JPG = "jpg"
    case PDF = "pdf"
    case TIFF = "tiff"
    case HEIC = "heic"
    var id: Self { self }
}

@MainActor
func captureScreen(type: CaptureType, display: Int = 1) async {
    let capturePath = Defaults[.capturePath]
    let fileType = Defaults[.captureFileType]
    let fileName = Defaults[.captureFileName]
    let copyToClipboard = Defaults[.copyToClipboard]
    let openInFinder = Defaults[.openInFinder]
    let uploadMedia = Defaults[.uploadMedia]
    let captureBinary = Defaults[.captureBinary]
    let uploadType = Defaults[.uploadType]
    let saveToDisk = Defaults[.saveToDisk]

    let timestamp = Int(Date().timeIntervalSince1970)
    let uniqueFilename = "\(fileName)-\(timestamp)"

    var path = "\(capturePath)\(uniqueFilename).\(fileType)"
    path = NSString(string: path).expandingTildeInPath

    let task = Process()
    task.launchPath = captureBinary
    task.arguments = type == CaptureType.SCREEN ? [type.rawValue, fileType.rawValue, "-D", "\(display)", path] : [type.rawValue, fileType.rawValue, path]
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
        let shouldSaveToDisk = saveToDisk
        let localFileURL = fileURL
        uploadFile(fileURL: fileURL, uploadType: uploadType) {
            Task { @MainActor in
                showToast(fileURL: localFileURL) {
                    NSSound.beep()

                    if !shouldSaveToDisk {
                        do {
                            try FileManager.default.removeItem(at: localFileURL)
                        } catch {
                            print("Error deleting the file: \(error)")
                        }
                    }
                }
            }
        }
    } else {
        let shouldSaveToDisk = saveToDisk
        let localFileURL = fileURL
        Task { @MainActor in
            showToast(fileURL: localFileURL) {
                NSSound.beep()

                if !shouldSaveToDisk {
                    do {
                        try FileManager.default.removeItem(at: localFileURL)
                    } catch {
                        print("Error deleting the file: \(error)")
                    }
                }
            }
        }
    }
    shareBasedOnPreferences(fileURL)
}
