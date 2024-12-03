//
//  CaptureEngine.swift
//  ishare
//
//  Created by Adrian Castro on 29.07.23.
//

@preconcurrency import AVFAudio
import Combine
import Defaults
import Foundation
import ScreenCaptureKit

/// A structure that contains the video data to render.
struct CapturedFrame : Sendable {
    static let invalid = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)

    let surface: IOSurface?
    let contentRect: CGRect
    let contentScale: CGFloat
    let scaleFactor: CGFloat
    var size: CGSize { contentRect.size }
}

/// An object that wraps an instance of `SCStream`, and returns its results as an `AsyncThrowingStream`.
class CaptureEngine: NSObject, @unchecked Sendable, SCRecordingOutputDelegate {
    private var recordMP4: Bool = false
    private var useHEVC: Bool = false

    private var stream: SCStream?
    private var fileURL: URL?
    private let videoSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.VideoSampleBufferQueue")
    private let audioSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.AudioSampleBufferQueue")

    // Performs average and peak power calculations on the audio samples.
    private let powerMeter = PowerMeter()
    var audioLevels: AudioLevels { powerMeter.levels }

    // Store the the startCapture continuation, so that you can cancel it when you call stopCapture().
    private var continuation: AsyncThrowingStream<CapturedFrame, any Error>.Continuation?

    private var startTime = Date()
    private var streamOutput: CaptureEngineStreamOutput?

    /// - Tag: StartCapture
    @MainActor func startCapture(configuration: SCStreamConfiguration, filter: SCContentFilter, fileURL: URL) -> AsyncThrowingStream<CapturedFrame, any Error> {
        let config = configuration
        let contentFilter = filter
        let outputURL = fileURL
        
        @Default(.recordMP4) var recordMP4
        @Default(.useHEVC) var useHEVC
        self.recordMP4 = recordMP4
        self.useHEVC = useHEVC
        
        return AsyncThrowingStream<CapturedFrame, any Error> { continuation in
            // The stream output object.
            let output = CaptureEngineStreamOutput(continuation: continuation)
            streamOutput = output

            streamOutput!.capturedFrameHandler = { continuation.yield($0) }
            streamOutput!.pcmBufferHandler = { self.powerMeter.process(buffer: $0) }
            self.startTime = Date()

            do {
                stream = SCStream(filter: contentFilter, configuration: config, delegate: streamOutput)
                self.fileURL = outputURL

                // Add a stream output to capture screen content.
                try stream?.addStreamOutput(streamOutput!, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
                try stream?.addStreamOutput(streamOutput!, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)

                let recordingConfiguration = SCRecordingOutputConfiguration()

                recordingConfiguration.outputURL = outputURL
                recordingConfiguration.outputFileType = self.recordMP4 ? .mp4 : .mov
                recordingConfiguration.videoCodecType = self.useHEVC ? .hevc : .h264

                let recordingOutput = SCRecordingOutput(configuration: recordingConfiguration, delegate: self)

                try stream?.addRecordingOutput(recordingOutput)

                stream?.startCapture()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    func stopCapture() async -> @Sendable (@escaping @Sendable (Result<URL, any Error>) -> Void) -> Void {
        return { [weak self] completion in
            guard let self = self else { return }
            enum ScreenRecorderError: Error {
                case missingFileURL
            }

            guard let url = fileURL else {
                completion(.failure(ScreenRecorderError.missingFileURL))
                return
            }

            // Stop the stream
            stream?.stopCapture()
            stream = nil
            
            // Return the file URL
            completion(.success(url))
        }
    }

    /// - Tag: UpdateStreamConfiguration
    func update(configuration: SCStreamConfiguration, filter: SCContentFilter) async {
        struct SendableParams: @unchecked Sendable {
            let configuration: SCStreamConfiguration
            let filter: SCContentFilter
        }
        
        let params = SendableParams(configuration: configuration, filter: filter)
        
        do {
            try await stream?.updateConfiguration(params.configuration)
            try await stream?.updateContentFilter(params.filter)
        } catch {
            print("Failed to update the stream session: \(String(describing: error))")
        }
    }
}

/// A class that handles output from an SCStream, and handles stream errors.
private class CaptureEngineStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    var pcmBufferHandler: ((AVAudioPCMBuffer) -> Void)?
    var capturedFrameHandler: ((CapturedFrame) -> Void)?

    // Store the the startCapture continuation, so you can cancel it if an error occurs.
    private var continuation: AsyncThrowingStream<CapturedFrame, any Error>.Continuation?

    init(continuation: AsyncThrowingStream<CapturedFrame, any Error>.Continuation?) {
        self.continuation = continuation
    }

    func stream(_: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        // Return early if the sample buffer is invalid.
        guard sampleBuffer.isValid else { return }

        // Determine which type of data the sample buffer contains.
        switch outputType {
        case .screen:
            // Create a CapturedFrame structure for a video sample buffer.
            guard let frame = createFrame(for: sampleBuffer) else { return }
            capturedFrameHandler?(frame)
        case .audio:
            // Create an AVAudioPCMBuffer from an audio sample buffer.
            guard let samples = createPCMBuffer(for: sampleBuffer) else { return }
            pcmBufferHandler?(samples)
        case .microphone:
            return
        @unknown default:
            fatalError("Encountered unknown stream output type: \(outputType)")
        }
    }

    /// Create a `CapturedFrame` for the video sample buffer.
    private func createFrame(for sampleBuffer: CMSampleBuffer) -> CapturedFrame? {
        // Retrieve the array of metadata attachments from the sample buffer.
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                                                                             createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
            let attachments = attachmentsArray.first else { return nil }

        // Validate the status of the frame. If it isn't `.complete`, return nil.
        guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue),
              status == .complete else { return nil }

        // Get the pixel buffer that contains the image data.
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil }

        // Get the backing IOSurface.
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return nil }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)

        // Retrieve the content rectangle, scale, and scale factor.
        guard let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let contentScale = attachments[.contentScale] as? CGFloat,
              let scaleFactor = attachments[.scaleFactor] as? CGFloat else { return nil }

        // Create a new frame with the relevant data.
        let frame = CapturedFrame(surface: surface,
                                  contentRect: contentRect,
                                  contentScale: contentScale,
                                  scaleFactor: scaleFactor)
        return frame
    }

    // Creates an AVAudioPCMBuffer instance on which to perform an average and peak audio level calculation.
    private func createPCMBuffer(for sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        var ablPointer: UnsafePointer<AudioBufferList>?
        try? sampleBuffer.withAudioBufferList { audioBufferList, _ in
            ablPointer = audioBufferList.unsafePointer
        }
        guard let audioBufferList = ablPointer,
              let absd = sampleBuffer.formatDescription?.audioStreamBasicDescription,
              let format = AVAudioFormat(standardFormatWithSampleRate: absd.mSampleRate, channels: absd.mChannelsPerFrame) else { return nil }
        return AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList)
    }

    func stream(_: SCStream, didStopWithError error: any Error) {
        if (error as NSError).code == -3817 {
            // User stopped the stream. Call AppDelegate's method to stop recording gracefully
            DispatchQueue.main.async {
                let pickerManager = ContentSharingPickerManager.shared
                pickerManager.deactivatePicker()
                AppDelegate.shared.stopRecording()
            }
        } else {
            // Handle other errors
            print("Stream stopped with error: \(error.localizedDescription)")
        }
        // Finish the AsyncThrowingStream if it's still running
        continuation?.finish(throwing: error)
    }
}
