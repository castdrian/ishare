//
//  UploadManager.swift
//  ishare
//
//  Created by Adrian Castro on 04.01.24.
//

import AppKit
import Foundation
import SwiftUI

@MainActor
final class UploadManager: @unchecked Sendable {
    static let shared = UploadManager()
    private var progress = Progress()
    private var statusItem: NSStatusItem?
    private var hostingView: NSHostingView<CircularProgressView>?

    private init() {
        setupMenu()
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            hostingView = NSHostingView(rootView: CircularProgressView(progress: 0))
            let viewSize: CGFloat = 18
            let xPosition = (button.bounds.width - viewSize) / 2
            let yPosition = (button.bounds.height - viewSize) / 2
            hostingView?.frame = CGRect(x: xPosition, y: yPosition, width: viewSize, height: viewSize)
            button.addSubview(hostingView!)
        }
    }

    func updateProgress(fraction: Double) {
        NSLog("Upload progress: %.2f%%", fraction * 100)
        Task { @MainActor in
            self.progress.completedUnitCount = Int64(fraction * 100)
            self.hostingView?.rootView = CircularProgressView(progress: fraction)
        }
    }

    func uploadCompleted() {
        NSLog("Upload completed, removing status item")
        Task { @MainActor in
            if let item = self.statusItem {
                NSStatusBar.system.removeStatusItem(item)
                self.statusItem = nil
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2.0)
                .opacity(0.3)
                .foregroundColor(Color.gray)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(Color.red, style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
        .frame(width: 14, height: 14)
    }
}
