//
//  HistoryGridView.swift
//  ishare
//
//  Created by Adrian Castro on 29.12.23.
//

import Foundation
import SwiftUI
import BezelNotification
import Alamofire

struct HistoryGridView: View {
    @State var uploadHistory: [HistoryItem]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)], spacing: 3) {
                ForEach(uploadHistory, id: \.self) { item in
                    if let urlStr = item.fileUrl, let url = URL(string: urlStr), url.pathExtension.lowercased() == "mp4" || url.pathExtension.lowercased() == "mov" {
                        ContextMenuWrapper(uploadHistory: $uploadHistory, item: item) {
                            VideoThumbnailView(url: url)
                                .frame(width: 100, height: 100)
                        }
                    } else {
                        ContextMenuWrapper(uploadHistory: $uploadHistory, item: item) {
                            HistoryItemView(urlString: item.fileUrl ?? "")
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
    @Binding var uploadHistory: [HistoryItem]
    let content: Content
    let item: HistoryItem
    
    init(uploadHistory: Binding<[HistoryItem]>, item: HistoryItem, @ViewBuilder content: () -> Content) {
        self._uploadHistory = uploadHistory
        self.item = item
        self.content = content()
    }
    
    var body: some View {
        content
            .contextMenu {
                Button("Copy URL") {
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(item.fileUrl ?? "", forType: .string)
                    BezelNotification.show(messageText: "Copied URL", icon: ToastIcon)
                }
                Button("Open in Browser") {
                    if let url = URL(string: item.fileUrl ?? "") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("Delete") {
                    print(item.deletionUrl ?? "nop")
                    if let deletionUrl = item.deletionUrl {
                        performDeletionRequest(deletionUrl: deletionUrl) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let message):
                                    print(message)
                                    if let index = uploadHistory.firstIndex(of: item) {
                                        uploadHistory.remove(at: index)
                                        BezelNotification.show(messageText: "Deleted", icon: ToastIcon)
                                    }
                                case .failure(let error):
                                    print("Deletion error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
    }
}

// ... Rest of your views ...

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
