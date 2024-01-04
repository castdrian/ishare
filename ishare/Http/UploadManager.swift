//
//  UploadManager.swift
//  ishare
//
//  Created by Adrian Castro on 04.01.24.
//

import Foundation
import AppKit
import SwiftUI

class UploadManager {
    static let shared = UploadManager()
    var progress = Progress()
    var statusItem: NSStatusItem?
    var hostingView: NSHostingView<CircularProgressView>?
    
    init() {
        setupMenu()
    }
    
    func setupMenu() {
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
        DispatchQueue.main.async {
            self.progress.completedUnitCount = Int64(fraction * 100)
            self.hostingView?.rootView = CircularProgressView(progress: fraction)
        }
    }
    
    func uploadCompleted() {
        DispatchQueue.main.async {
            if let item = self.statusItem {
                NSStatusBar.system.removeStatusItem(item)
                self.statusItem = nil
            }
        }
    }
}

struct CircularProgressView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2.0)
                .opacity(0.3)
                .foregroundColor(Color.gray)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(Color.red, style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
        .frame(width: 14, height: 14)
    }
}
