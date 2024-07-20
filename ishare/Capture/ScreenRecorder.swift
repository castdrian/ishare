//
//  ScreenRecorder.swift
//  ishare
//
//  Created by Adrian Castro on 29.07.23.
//

import Combine
import Defaults
import Foundation
import ScreenCaptureKit
import SwiftUI

class AudioLevelsProvider: ObservableObject {
    @Published var audioLevels = AudioLevels.zero
}

@MainActor
class ScreenRecorder: ObservableObject {
    @Published var isRunning = false
    @Published var isAppAudioExcluded = false
    @Published private(set) var audioLevelsProvider = AudioLevelsProvider()

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

        pickerManager.contentSelectionFailed = { _ in
            self.isRunning = false
        }

        let config = SCStreamConfiguration()
        let dummyFilter = SCContentFilter()
        let stream = SCStream(filter: dummyFilter, configuration: config, delegate: nil)

        pickerManager.setupPicker(stream: stream)
        pickerManager.showPicker()
    }

    func stop(completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            let stopClosure = await captureEngine.stopCapture()
            stopClosure { result in
                switch result {
                case let .success(url):
                    completion(.success(url))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
            stopAudioMetering()
            isRunning = false
        }
    }

    private func startAudioMetering() {
        audioMeterCancellable = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            audioLevelsProvider.audioLevels = captureEngine.audioLevels
        }
    }

    private func stopAudioMetering() {
        audioMeterCancellable?.cancel()
        audioLevelsProvider.audioLevels = AudioLevels.zero
    }

    private func startCapture(with filter: SCContentFilter, fileURL: URL) async {
        @Default(.useHDR) var useHDR
        
        let config: SCStreamConfiguration
        if useHDR {
            config = SCStreamConfiguration(preset: .captureHDRStreamCanonicalDisplay)
        } else {
            config = SCStreamConfiguration()
        }

        isRunning = true

        do {
            // Iterating over frames to keep the stream active
            for try await _ in captureEngine.startCapture(configuration: config, filter: filter, fileURL: fileURL) {}
        } catch {
            // Handle errors if necessary
            print(error.localizedDescription)
        }
    }
}
