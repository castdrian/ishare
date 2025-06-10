import SwiftUI

/// A wrapper that safely handles view content in sendable closures
struct SafeContentWrapper<Content: View>: View {
    let content: Content
    
    var body: some View {
        content
    }
}
