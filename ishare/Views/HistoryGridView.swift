//
//  HistoryGridView.swift
//  ishare
//
//  Created by Adrian Castro on 29.12.23.
//

import Foundation
import SwiftUI
import BezelNotification

struct HistoryGridView: View {
    var uploadHistory: [String]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)], spacing: 3) {
                ForEach(uploadHistory, id: \.self) { item in
                    if let url = URL(string: item), url.pathExtension.lowercased() == "mp4" || url.pathExtension.lowercased() == "mov" {
                        ContextMenuWrapper(item: item) {
                            VideoThumbnailView(url: url)
                                .frame(width: 100, height: 100)
                        }
                    } else {
                        ContextMenuWrapper(item: item) {
                            HistoryItemView(urlString: item)
                                .frame(width: 100, height: 100)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ContextMenuWrapper<Content: View>: View {
    @State private var isHovered = false
    let content: Content
    let item: String

    init(item: String, @ViewBuilder content: () -> Content) {
        self.item = item
        self.content = content()
    }

    var body: some View {
        content
            .scaleEffect(isHovered ? 1.05 : 1.0) // Scale effect on hover
            .shadow(color: isHovered ? .gray : .clear, radius: 10) // Shadow effect
            .background(isHovered ? Color.gray.opacity(0.2) : Color.clear) // Background color change
            .cornerRadius(8) // Rounded corners
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.gray : Color.clear, lineWidth: 2) // Border
            )
            .onHover { hovering in
                withAnimation {
                    isHovered = hovering
                }
            }
            .contextMenu {
                Button("Copy URL") {
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(item, forType: .string)
                    BezelNotification.show(messageText: "Copied URL", icon: ToastIcon)
                }
                Button("Open in Browser") {
                    if let url = URL(string: item) {
                        NSWorkspace.shared.open(url)
                    }
                }
//                Button("Delete") {
//                    // Action for the third menu item
//                }
            }
    }
}

struct VideoThumbnailView: View {
    var url: URL

    var body: some View {
        Image(systemName: "video")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
    }
}

struct HistoryItemView: View {
    var urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
        } else {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
        }
    }
}
