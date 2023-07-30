//
//  PreviewPopover.swift
//  ishare
//
//  Created by Adrian Castro on 30.07.23.
//

import SwiftUI

struct CapturePreviewPopup: View {
    let capturePreview: CapturePreview
    
    var body: some View {
        VStack {
            capturePreview
                .frame(width: 350, height: 200)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
    }
}

func showCapturePreviewPopup(capturePreview: CapturePreview) -> NSWindow {
    let popup = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 350, height: 200),
        styleMask: [.borderless],
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
