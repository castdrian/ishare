//
//  PreviewImage.swift
//  ishare
//
//  Created by Adrian Castro on 30.08.23.
//

import Combine
import Foundation
import SwiftUI

enum ImagePhase {
    case empty
    case success(NSImage)
    case failure
}

struct PreviewImage<Content: View>: View {
    @State private var image: NSImage? = nil
    @State private var phase: ImagePhase = .empty

    let url: URL?
    let content: (ImagePhase) -> Content

    init(url: URL?, @ViewBuilder content: @escaping (ImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .onAppear {
                guard let url else {
                    return
                }
                let config = URLSessionConfiguration.default
                config.httpMaximumConnectionsPerHost = 100
                let session = URLSession(configuration: config)
                let task = session.dataTask(with: url) { data, _, _ in
                    if let data, let uiImage = NSImage(data: data) {
                        DispatchQueue.main.async {
                            image = uiImage
                            phase = .success(uiImage)
                        }
                    } else {
                        DispatchQueue.main.async {
                            phase = .failure
                        }
                    }
                }
                task.resume()
            }
    }
}
