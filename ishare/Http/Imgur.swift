//
//  Imgur.swift
//  ishare
//
//  Created by Adrian Castro on 14.07.23.
//

import BezelNotification
import SwiftyJSON
import Alamofire
import Foundation
import Defaults
import AppKit

func imgurUpload(_ fileURL: URL, completion: @escaping () -> Void) {
    @Default(.imgurClientId) var imgurClientId
    
    let url = "https://api.imgur.com/3/upload"
    
    let fileFormName = determineFileFormName(for: fileURL)
    let fileName = "ishare.\(fileURL.pathExtension)"
    let mimeType = mimeTypeForPathExtension(fileURL.pathExtension)

    AF.upload(multipartFormData: { multipartFormData in
        multipartFormData.append(fileURL, withName: fileFormName, fileName: fileName, mimeType: mimeType)
    }, to: url, method: .post, headers: ["Authorization": "Client-ID " + imgurClientId])
    .uploadProgress { progress in
        UploadManager.shared.updateProgress(fraction: progress.fractionCompleted)
    }
    .response { response in
        UploadManager.shared.uploadCompleted()
        if let data = response.data {
            let json = JSON(data)
            if let link = json["data"]["link"].string {
                print("Image uploaded successfully. Link: \(link)")

                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(link, forType: .string)

                let historyItem = HistoryItem(fileUrl: link)
                addToUploadHistory(historyItem)
                completion()
            } else {
                print("Error parsing response or retrieving image link")
                BezelNotification.show(messageText: "An error occured", icon: ToastIcon)
                completion()
            }
        }
    }
}

func determineFileFormName(for fileURL: URL) -> String {
    switch fileURL.pathExtension.lowercased() {
    case "mp4", "mov":
        return "video"
    default:
        return "image"
    }
}

