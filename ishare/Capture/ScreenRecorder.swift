//
//  ScreenRecorder.swift
//  ishare
//
//  Created by Adrian Castro on 29.07.23.
//

import Foundation
import ScreenCaptureKit
import Combine
import SwiftUI
import Defaults

class AudioLevelsProvider: ObservableObject {
    @Published var audioLevels = AudioLevels.zero
}

@MainActor
class ScreenRecorder: ObservableObject {
    private let movie = MovieRecorder(audioSettings: [:], videoSettings: [:], videoTransform: .identity)
    
    @Published var isTimerRunning = false
    @Published var startTime = Date()
    @Published var timerString = "00:00"
    @Published var isRunning = false
    @Published var isAudioCaptureEnabled = true
    @Published var isAppAudioExcluded = false
    @Published private(set) var audioLevelsProvider = AudioLevelsProvider()
    @Published var contentSize = CGSize(width: 1, height: 1)
    
    private var scaleFactor: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }
    private var audioMeterCancellable: AnyCancellable?
    private let captureEngine = CaptureEngine()
    
    var canRecord: Bool {
        get async {
            do {
                // If the app doesn't have Screen Recording permission, this call generates an exception.
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                return true
            } catch {
                return false
            }
        }
    }
    
    func start(_ fileURL: URL) async {
        guard !isRunning else { return }
        isRunning = true
        
        let pickerManager = ContentSharingPickerManager.shared
        pickerManager.contentSelected = { [weak self] filter, _ in
            Task {
                await self?.startCapture(with: filter, fileURL: fileURL)
            }
        }
        
        pickerManager.contentSelectionCancelled = { _ in
            self.isRunning = false
            Task {
                self.stop(completion:)
            }

        }
        
        pickerManager.contentSelectionFailed = { error in
            self.isRunning = false
        }
        
        let config = SCStreamConfiguration()
        let dummyFilter = SCContentFilter()
        let stream = SCStream(filter: dummyFilter, configuration: config, delegate: nil)
        pickerManager.setupPicker(stream: stream)
        pickerManager.showPicker()
    }
    
    func stop(completion: @escaping (Result<URL, Error>) -> Void) {
        captureEngine.stopCapture { url, error in
            if let error = error {
                completion(.failure(error))
            } else if let url = url {
                completion(.success(url))
            }
        }
        stopAudioMetering()
        isRunning = false
        startTime = Date()
    }
    private func startAudioMetering() {
        audioMeterCancellable = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelsProvider.audioLevels = self.captureEngine.audioLevels
        }
    }
    
    private func stopAudioMetering() {
        audioMeterCancellable?.cancel()
        audioLevelsProvider.audioLevels = AudioLevels.zero
    }
    
    private func startCapture(with filter: SCContentFilter, fileURL: URL) async {
        let config = SCStreamConfiguration()
        isRunning = true

        do {
            // Iterating over frames to keep the stream active
            for try await _ in captureEngine.startCapture(configuration: config, filter: filter, movie: movie, fileURL: fileURL) {
            }
        } catch {
            // Handle errors if necessary
            print(error.localizedDescription)
        }
    }
}
