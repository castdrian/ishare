//
//  VideoCapture.swift
//  ishare
//
//  Created by Adrian Castro on 24.07.23.
//

import AppKit
import AVFoundation
import BezelNotification
import Cocoa
import Defaults
import Foundation
import ScreenCaptureKit
import SwiftUI

@MainActor
func recordScreen(gif: Bool? = false) {
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

    if gif ?? false {
        AppDelegate.shared.recordGif = true
    }

    Task {
        if await (screenRecorder?.canRecord) != nil {
            await screenRecorder?.start(fileURL)
        } else {
            BezelNotification.show(messageText: "Missing permission", icon: ToastIcon)
        }
    }
}

func postRecordingTasks(_ URL: URL, _ recordGif: Bool) {
    @Default(.copyToClipboard) var copyToClipboard
    @Default(.openInFinder) var openInFinder
    @Default(.recordingPath) var recordingPath
    @Default(.recordingFileName) var fileName
    @Default(.uploadType) var uploadType
    @Default(.uploadMedia) var uploadMedia
    @Default(.saveToDisk) var saveToDisk

    func processGif(from url: URL, completion: @escaping (URL?) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let gifURL = try await exportGif(from: url)
                completion(gifURL)
            } catch {
                print("Error processing GIF: \(error)")
                completion(nil)
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    var fileURL = URL

    if recordGif {
        processGif(from: fileURL) { resultingURL in
            if let newURL = resultingURL {
                fileURL = newURL
            }
        }
    }

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
    AppDelegate.shared.recordGif = false
    shareBasedOnPreferences(fileURL)
}

func exportGif(from videoURL: URL) async throws -> URL {
    let asset = AVURLAsset(url: videoURL)

    let duration: CMTime = try await asset.load(.duration)
    let videoTracks = try await asset.loadTracks(withMediaType: .video)
    guard let firstVideoTrack = videoTracks.first else {
        throw NSError(domain: "com.castdrian.ishare", code: 3, userInfo: [NSLocalizedDescriptionKey: "No video track found in the asset"])
    }
    let size = try await firstVideoTrack.load(.naturalSize)

    let totalDuration = duration.seconds
    let frameRate: CGFloat = 30
    let totalFrames = Int(totalDuration * TimeInterval(frameRate))
    var timeValues: [NSValue] = []

    for frameNumber in 0 ..< totalFrames {
        let time = CMTime(seconds: Double(frameNumber) / Double(frameRate), preferredTimescale: Int32(NSEC_PER_SEC))
        timeValues.append(NSValue(time: time))
    }

    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

    let generator = AVAssetImageGenerator(asset: asset)
    generator.requestedTimeToleranceBefore = CMTime.zero
    generator.requestedTimeToleranceAfter = CMTime.zero
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = rect.size

    let delayBetweenFrames: TimeInterval = 1.0 / TimeInterval(frameRate)
    let fileProperties: [String: Any] = [
        kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFLoopCount as String: 0,
        ],
    ]
    let frameProperties: [String: Any] = [
        kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFDelayTime: delayBetweenFrames,
        ],
    ]

    let outputURL = videoURL.deletingPathExtension().appendingPathExtension("gif")
    let imageDestination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.gif.identifier as CFString, totalFrames, nil)!
    CGImageDestinationSetProperties(imageDestination, fileProperties as CFDictionary)

    return try await withCheckedThrowingContinuation { continuation in
        generator.generateCGImagesAsynchronously(forTimes: timeValues) { requestedTime, resultingImage, _, _, _ in
            if let image = resultingImage {
                CGImageDestinationAddImage(imageDestination, image, frameProperties as CFDictionary)
            }
            if requestedTime == timeValues.last?.timeValue {
                let success = CGImageDestinationFinalize(imageDestination)
                if success {
                    do {
                        try FileManager.default.removeItem(at: videoURL)
                        continuation.resume(returning: outputURL)
                    } catch {
                        continuation.resume(throwing: NSError(domain: "com.castdrian.ishare", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to delete the original video"]))
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "com.castdrian.ishare", code: 2, userInfo: [NSLocalizedDescriptionKey: "Gif export failed"]))
                }
            }
        }
    }
}
