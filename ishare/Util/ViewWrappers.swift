import SwiftUI

/// A wrapper that safely handles view content in sendable closures.
/// 
/// `SafeContentWrapper` is useful when you want to encapsulate a SwiftUI view
/// in a way that ensures it can be safely passed around in sendable contexts.
/// 
/// Example usage:
/// ```
/// struct ExampleView: View {
///     var body: some View {
///         SafeContentWrapper(content: Text("Hello, world!"))
///     }
/// }
/// ```
struct SafeContentWrapper<Content: View>: View {
    let content: Content
    
    var body: some View {
        content
    }
}
