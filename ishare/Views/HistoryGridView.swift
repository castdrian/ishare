//
//  HistoryGridView.swift
//  ishare
//
//  Created by Adrian Castro on 29.12.23.
//

import Alamofire
import BezelNotification
import Defaults
import Foundation
import SwiftUI

struct HistoryGridView: View {
    @Default(.uploadHistory) var uploadHistory
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)], spacing: 3) {
                ForEach(uploadHistory, id: \.self) { item in
                    // Use regular context menu directly
                    itemView(for: item)
                        .frame(width: 100, height: 100)
                        .contextMenu {
                            Button("Copy URL".localized()) {
                                copyURL(item)
                            }
                            Button("Open in Browser".localized()) {
                                openInBrowser(item)
                            }
                            Button("Delete".localized()) {
                                deleteItem(item)
                            }
                        }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    @ViewBuilder
    private func itemView(for item: HistoryItem) -> some View {
        if let urlStr = item.fileUrl, 
           let url = URL(string: urlStr), 
           url.pathExtension.lowercased() == "mp4" || url.pathExtension.lowercased() == "mov" {
            VideoThumbnailView(url: url)
        } else {
            HistoryItemView(urlString: item.fileUrl ?? "")
        }
    }
    
    private func copyURL(_ item: HistoryItem) {
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(item.fileUrl ?? "", forType: .string)
        BezelNotification.show(messageText: "Copied URL".localized(), icon: ToastIcon)
    }
    
    private func openInBrowser(_ item: HistoryItem) {
        if let url = URL(string: item.fileUrl ?? "") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func deleteItem(_ item: HistoryItem) {
        guard let deletionUrl = item.deletionUrl else { return }
        
        Task {
            do {
                let message = try await performDeletionAsync(deletionUrl)
                print(message)
                Task { @MainActor in
                    if let index = uploadHistory.firstIndex(of: item) {
                        uploadHistory.remove(at: index)
                        BezelNotification.show(messageText: "Deleted".localized(), icon: ToastIcon)
                    }
                }
            } catch {
                print("Deletion error: \(error.localizedDescription)")
                Task { @MainActor in
                    if let index = uploadHistory.firstIndex(of: item) {
                        uploadHistory.remove(at: index)
                        BezelNotification.show(messageText: "Deleted".localized(), icon: ToastIcon)
                    }
                }
            }
        }
    }
    
    private func performDeletionAsync(_ deletionUrl: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            performDeletionRequest(deletionUrl: deletionUrl) { result in
                switch result {
                case .success(let message):
                    continuation.resume(returning: message)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
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
