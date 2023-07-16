import SwiftUI

struct ToastPopoverView: View {
    let thumbnailImage: NSImage
    let fileURL: URL
    
    var body: some View {
        Image(nsImage: thumbnailImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
            .foregroundColor(Color(NSColor.labelColor))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .animation(Animation.easeInOut(duration: 1.0), value: thumbnailImage)
            .onTapGesture {
                        NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
                    }
    }
}

func showToast(fileURL: URL) {
    guard let thumbnailImage = NSImage(contentsOf: fileURL) else {
        return
    }
    
    let toastWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 250, height: 150),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    
    toastWindow.level = .floating
    toastWindow.isOpaque = false
    toastWindow.backgroundColor = .clear
    toastWindow.isMovableByWindowBackground = false
    toastWindow.contentView = NSHostingView(
            rootView: ToastPopoverView(thumbnailImage: thumbnailImage, fileURL: fileURL)
    )
    
    toastWindow.makeKeyAndOrderFront(nil)
    let screenSize = NSScreen.main?.frame.size ?? .zero
    let originX = screenSize.width - toastWindow.frame.width - 20
    let originY = screenSize.height - toastWindow.frame.height - 20
    toastWindow.setFrameOrigin(NSPoint(x: originX, y: originY))

    let fadeDuration = 0.2
    toastWindow.alphaValue = 0.0
    
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = fadeDuration
        toastWindow.animator().alphaValue = 1.0
    }) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = fadeDuration
                toastWindow.animator().alphaValue = 0.0
            }) {
                toastWindow.orderOut(nil)
            }
        }
    }
}
