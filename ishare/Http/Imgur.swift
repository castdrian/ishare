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
    @Default(.captureFileType) var fileType
    @Default(.imgurClientId) var imgurClientId
    
    let url = "https://api.imgur.com/3/upload"
    
    var fileFormName: String
    var fileName: String
    var mimeType: String
    
    switch fileURL.pathExtension {
    case "mp4":
        fileFormName = "video"
        fileName = "ishare.mp4"
        mimeType = "video/mp4"
    case "mov":
        fileFormName = "video"
        fileName = "ishare.mov"
        mimeType = "video/mov"
    case "gif":
        fileFormName = "image"
        fileName = "ishare.gif"
        mimeType = "image/gif"
    default:
        fileFormName = "image"
        fileName = "ishare.\(fileType)"
        mimeType = "image/\(fileType)"
    }
        
    AF.upload(multipartFormData: { multipartFormData in
        multipartFormData.append(fileURL, withName: fileFormName, fileName: fileName, mimeType: mimeType)
    }, to: url, method: .post, headers: ["Authorization": "Client-ID " + imgurClientId]).response { response in
        if let data = response.data {
            let json = JSON(data)
            if let link = json["data"]["link"].string {
                print("Image uploaded successfully. Link: \(link)")
                
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                
                pasteboard.setString(link, forType: .string)
                completion()
            } else {
                print("Error parsing response or retrieving image link")
                BezelNotification.show(messageText: "An error occured", icon: ToastIcon)
                completion()
            }
        }
    }
}
