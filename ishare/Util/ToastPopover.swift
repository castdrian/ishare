import AVFoundation
import Defaults
import SwiftUI

struct ToastPopoverView: View {
    let thumbnailImage: NSImage
    let fileURL: URL
    @Default(.saveToDisk) var saveToDisk
    @State private var isDragging = false

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
            .opacity(isDragging ? 0 : 1)
            .onTapGesture {
                if saveToDisk {
                    NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
                }
            }
            .onDrag {
                isDragging = true
                let itemProvider = NSItemProvider(object: fileURL as NSURL)
                itemProvider.suggestedName = fileURL.lastPathComponent
                return itemProvider
            }
            .onDrop(of: [UTType.url], isTargeted: nil) { _ -> Bool in
                isDragging = false
                return true
            }
    }
}

@MainActor
func showToast(fileURL: URL, completion: (@Sendable () -> Void)? = nil) {
    if fileURL.pathExtension == "mov" || fileURL.pathExtension == "mp4" {
        let localCompletion = completion
        Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: fileURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 2, preferredTimescale: 60)

            do {
                let cgImage = try await imageGenerator.image(at: time)
                let imageData = cgImage.image.dataProvider?.data
                let width = cgImage.image.width
                let height = cgImage.image.height

                guard imageData != nil else {
                    throw NSError(domain: "ImageErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get image data"])
                }

                await MainActor.run {
                    let thumbnailImage = NSImage(cgImage: cgImage.image, size: CGSize(width: width, height: height))
                    showThumbnailAndToast(fileURL: fileURL, thumbnailImage: thumbnailImage, completion: localCompletion)
                }
            } catch {
                print("Error generating thumbnail: \(error)")
            }
        }
    } else {
        showThumbnailAndToast(fileURL: fileURL, thumbnailImage: NSImage(contentsOf: fileURL)!, completion: completion)
    }
}

@MainActor
private func showThumbnailAndToast(fileURL: URL, thumbnailImage: NSImage, completion: (() -> Void)? = nil) {
    let toastTimeout = Defaults[.toastTimeout]
    let localCompletion = completion
    let toastWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    toastWindow.backgroundColor = .clear
    toastWindow.isOpaque = false
    toastWindow.level = .floating
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
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(toastTimeout))) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = fadeDuration
                toastWindow.animator().alphaValue = 0.0
            }) {
                toastWindow.orderOut(nil)
                localCompletion?()
            }
        }
    }
}
