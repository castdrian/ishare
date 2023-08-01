//
//  CaptureEngine.swift
//  ishare
//
//  Created by Adrian Castro on 29.07.23.
//

import Foundation
import AVFAudio
import ScreenCaptureKit
import OSLog
import Combine
import AVFoundation

struct CapturedFrame {
    static let invalid = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)
    
    let surface: IOSurface?
    let contentRect: CGRect
    let contentScale: CGFloat
    let scaleFactor: CGFloat
    var size: CGSize { contentRect.size }
}

class CaptureEngine: NSObject, @unchecked Sendable {
    
    private let logger = Logger()
    
    private var stream: SCStream?
    private let videoSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.VideoSampleBufferQueue")
    private let audioSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.AudioSampleBufferQueue")
    
    private let powerMeter = PowerMeter()
    var audioLevels: AudioLevels { powerMeter.levels }
    
    private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
    
    func startCapture(configuration: SCStreamConfiguration, filter: SCContentFilter, fileURL: URL) -> AsyncThrowingStream<CapturedFrame, Error> {
        AsyncThrowingStream<CapturedFrame, Error> { continuation in
            let streamOutput = CaptureEngineStreamOutput(continuation: continuation, outputURL: fileURL)
            streamOutput.capturedFrameHandler = { continuation.yield($0) }
            streamOutput.pcmBufferHandler = { self.powerMeter.process(buffer: $0) }
            
            do {
                self.stream = SCStream(filter: filter, configuration: configuration, delegate: streamOutput)
                try self.stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: self.videoSampleBufferQueue)
                try self.stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: self.audioSampleBufferQueue)
                self.stream?.startCapture()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
    
    func stopCapture() async {
        do {
            try await stream?.stopCapture()
            continuation?.finish()
        } catch {
            continuation?.finish(throwing: error)
        }
        powerMeter.processSilence()
    }
    
    func update(configuration: SCStreamConfiguration, filter: SCContentFilter) async {
        do {
            try await stream?.updateConfiguration(configuration)
            try await stream?.updateContentFilter(filter)
        } catch {
            logger.error("Failed to update the stream session: \(String(describing: error))")
        }
    }
}

private class CaptureEngineStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    
    var pcmBufferHandler: ((AVAudioPCMBuffer) -> Void)?
    var capturedFrameHandler: ((CapturedFrame) -> Void)?
    
    private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
    private let outputURL: URL
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var videoInputAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    init(continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?, outputURL: URL) {
        self.continuation = continuation
        self.outputURL = outputURL
        super.init()
        
        setupWriter()
    }
    
    private func setupWriter() {
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            
            let videoOutputSettings: [String : Any] = [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : 1920,
                AVVideoHeightKey : 1080
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
            
            guard let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true else {
                return
            }
            
            assetWriter?.add(videoInput)
            
            let sourcePixelBufferAttributes: [String : Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String : 1920,
                kCVPixelBufferHeightKey as String : 1080
            ]
            
            videoInputAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
            
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: .zero)
        } catch {
            print("Failed to set up writer: \(error)")
        }
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard sampleBuffer.isValid else { return }
        
        switch outputType {
        case .screen:
            guard let frame = createFrame(for: sampleBuffer) else { return }
            capturedFrameHandler?(frame)
        case .audio:
            guard let samples = createPCMBuffer(for: sampleBuffer) else { return }
            pcmBufferHandler?(samples)
        @unknown default:
            fatalError("Encountered unknown stream output type: \(outputType)")
        }
    }
    
    private func createFrame(for sampleBuffer: CMSampleBuffer) -> CapturedFrame? {
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                                                                             createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first else { return nil }
        
        guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue),
              status == .complete else { return nil }
        
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil }
        
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return nil }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        
        guard let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let contentScale = attachments[.contentScale] as? CGFloat,
              let scaleFactor = attachments[.scaleFactor] as? CGFloat else { return nil }
        
        if let videoInputAdaptor = videoInputAdaptor, let videoInput = videoInput, videoInput.isReadyForMoreMediaData {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoInputAdaptor.append(pixelBuffer, withPresentationTime: timestamp)
        }
        
        let frame = CapturedFrame(surface: surface,
                                  contentRect: contentRect,
                                  contentScale: contentScale,
                                  scaleFactor: scaleFactor)
        return frame
    }
    
    private func createPCMBuffer(for sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        var ablPointer: UnsafePointer<AudioBufferList>?
        try? sampleBuffer.withAudioBufferList { audioBufferList, blockBuffer in
            ablPointer = audioBufferList.unsafePointer
        }
        guard let audioBufferList = ablPointer,
              let formatDescription = sampleBuffer.formatDescription,
              let asbd = formatDescription.audioStreamBasicDescription else { return nil }

        return withUnsafePointer(to: asbd) { pointer in
            guard let format = AVAudioFormat(streamDescription: pointer) else { return nil }
            return AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList)
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        videoInput?.markAsFinished()
        assetWriter?.finishWriting {
            print("Writing finished, file saved to: \(self.outputURL)")
        }
        continuation?.finish(throwing: error)
    }
}
