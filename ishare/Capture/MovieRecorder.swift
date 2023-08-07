//
//  MovieRecorder.swift
//  ishare
//
//  Created by Adrian Castro on 02.08.23.
//

import SwiftUI

import Foundation
import AVFoundation
import Defaults

class MovieRecorder {
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var videoTransform: CGAffineTransform
    private var videoSettings: [String: Any]
    private var audioSettings: [String: Any]
    private(set) var isRecording = false
    @Default(.recordMP4) var recordMP4
    @Default(.useHEVC) var useHEVC

    init(audioSettings: [String: Any], videoSettings: [String: Any], videoTransform: CGAffineTransform) {
        self.audioSettings = audioSettings
        self.videoSettings = videoSettings
        self.videoTransform = videoTransform
    }

    private func append(toPath path: String,
                        withPathComponent pathComponent: String) -> String? {
        if var pathURL = URL(string: path) {
            pathURL.appendPathComponent(pathComponent)

            return pathURL.absoluteString
        }

        return nil
    }

    func startRecording(fileURL: URL, height: Int, width: Int) {
        guard let assetWriter = try? AVAssetWriter(url: fileURL, fileType: recordMP4 ? .mp4 : .mov) else {
            return
        }

        // Add an audio input
        let audioSettings = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsNonInterleaved: false,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false
                ] as [String : Any]

        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterAudioInput)

        let videoSettings = [
            AVVideoCodecKey: useHEVC ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
                    AVVideoWidthKey: width,
                    AVVideoHeightKey: height
                ] as [String : Any]

        // Add a video input
        DispatchQueue.global(qos: .background).async { [self] in
            let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            
            assetWriterVideoInput.expectsMediaDataInRealTime = true
            assetWriterVideoInput.transform = videoTransform
            assetWriter.add(assetWriterVideoInput)

            self.assetWriter = assetWriter
            self.assetWriterAudioInput = assetWriterAudioInput
            self.assetWriterVideoInput = assetWriterVideoInput
        }

        isRecording = true
    }

    func stopRecording(completion: @escaping (URL) -> Void) {
        guard let assetWriter = assetWriter else {
            return
        }

        self.isRecording = false
        self.assetWriter = nil

        assetWriter.finishWriting {
            completion(assetWriter.outputURL)
        }
    }

    func recordVideo(sampleBuffer: CMSampleBuffer) {
        guard isRecording,
            let assetWriter = assetWriter else {
                return
        }

        if assetWriter.status == .unknown {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        } else if assetWriter.status == .writing {
            if let input = assetWriterVideoInput,
                input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }

    func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard isRecording,
            let assetWriter = assetWriter,
            assetWriter.status == .writing,
            let input = assetWriterAudioInput,
            input.isReadyForMoreMediaData else {
                return
        }

        input.append(sampleBuffer)
    }
}
