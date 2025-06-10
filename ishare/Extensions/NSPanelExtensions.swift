import AppKit
import Foundation

extension NSSavePanel {
    func beginAsyncModal() async -> NSApplication.ModalResponse {
        return await withCheckedContinuation { continuation in
            self.begin { response in
                continuation.resume(returning: response)
            }
        }
    }
}
