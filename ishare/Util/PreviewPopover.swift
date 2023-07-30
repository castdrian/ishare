//
//  PreviewPopover.swift
//  ishare
//
//  Created by Adrian Castro on 30.07.23.
//

import SwiftUI
import AppKit
import ScreenCaptureKit

struct CapturePreviewPopup: View {
    let capturePreview: CapturePreview
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                capturePreview
                    .padding()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .aspectRatio(nil, contentMode: .fill)
            
                HStack(spacing: 4) {
                    Text("REC")
                        .foregroundColor(.red)
                        .bold()
                        .shadow(color: .black, radius: 5, x: 0, y: 0)
                    BlinkingRedDot()
                        .frame(width: 10, height: 10)
                }
                .padding(10)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(VisualEffectView())
    }
}

struct BlinkingRedDot: NSViewRepresentable {
    class BlinkingRedDotView: NSView {
        override func draw(_ dirtyRect: NSRect) {
            let dotRect = NSRect(x: 0, y: 0, width: 10, height: 10)
            let dotPath = NSBezierPath(ovalIn: dotRect)
            NSColor.red.setFill()
            dotPath.fill()
        }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                self.isHidden.toggle()
            }
        }
    }
    
    func makeNSView(context: NSViewRepresentableContext<Self>) -> NSView {
        return BlinkingRedDotView()
    }
    
    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<Self>) {
    }
}

func showCapturePreviewPopup(capturePreview: CapturePreview, display: SCDisplay? = nil, window: SCWindow? = nil) -> NSWindow {
    let popup = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
        styleMask: [.borderless, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )
    
    popup.level = .floating
    popup.isOpaque = false
    popup.backgroundColor = .clear
    popup.isMovableByWindowBackground = false
    popup.contentView = NSHostingView(
        rootView: CapturePreviewPopup(capturePreview: capturePreview)
    )
    
    let borderThickness: CGFloat = 4
    popup.contentView?.wantsLayer = true
    popup.contentView?.layer?.cornerRadius = borderThickness
    popup.contentView?.layer?.borderWidth = borderThickness
    popup.contentView?.layer?.borderColor = NSColor.black.cgColor
    
    var targetWidth: CGFloat = 400
    var targetHeight: CGFloat = 250
    
    if let display = display {
        targetWidth = display.frame.width * 0.225
        targetHeight = display.frame.height * 0.225
    } else if let window = window {
        targetWidth = window.frame.width * 0.225
        targetHeight = window.frame.height * 0.225
    }
    
    let scaleFactor = min(targetWidth / 400, targetHeight / 250)
    popup.setContentSize(NSSize(width: 400 * scaleFactor, height: 250 * scaleFactor))
    
    popup.makeKeyAndOrderFront(nil)
    
    let screenSize = NSScreen.main?.frame.size ?? .zero
    let originX = screenSize.width - popup.frame.width - 20
    let originY = screenSize.height - popup.frame.height - 20
    popup.setFrameOrigin(NSPoint(x: originX, y: originY))
    
    let fadeDuration = 0.2
    popup.alphaValue = 0.0
    
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = fadeDuration
        popup.animator().alphaValue = 1.0
    })
    
    return popup
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: NSViewRepresentableContext<Self>) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .withinWindow
        visualEffectView.material = .sidebar
        visualEffectView.appearance = NSAppearance(named: .vibrantDark)
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: NSViewRepresentableContext<Self>) {}
}
