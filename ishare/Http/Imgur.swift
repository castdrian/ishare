//
//  Imgur.swift
//  ishare
//
//  Created by Adrian Castro on 14.07.23.
//

import Alamofire
import Foundation
import Defaults
import AppKit

func imgurUpload(_ fileURL: URL, completion: @escaping () -> Void) {
    guard let base64Image = imageToBase64(fileURL) else {
        print("Failed to convert image to base64")
        return
    }
    
    @Default(.captureFileType) var fileType
    @Default(.imgurClientId) var imgurClientId
    
    let url = "https://api.imgur.com/3/upload"
    
    AF.upload(multipartFormData: { multipartFormData in
        if let imageData = Data(base64Encoded: base64Image) {
            multipartFormData.append(imageData, withName: "image", fileName: "ishare.\(fileType)", mimeType: "image/\(fileType)")
        }
        
        let parameters = ["image": base64Image]
        for (key, value) in parameters {
            if let data = value.data(using: .utf8) {
                multipartFormData.append(data, withName: key)
            }
        }
    }, to: url, method: .post, headers: ["Authorization": "Client-ID " + imgurClientId]).response { response in
        if let data = response.data,
           let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
           let imageDic = json["data"] as? [String: Any],
           let link = imageDic["link"] as? String {
            print("Image uploaded successfully. Link: \(link)")
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
                
            pasteboard.setString(link, forType: .string)
            completion()
        } else {
            print("Error parsing response or retrieving image link")
            completion()
        }
    }
}


func imageToBase64(_ fileURL: URL) -> String? {
    do {
        let imageData = try Data(contentsOf: fileURL)
        let base64String = imageData.base64EncodedString()
        return base64String
    } catch {
        print("Error reading file: \(error)")
        return nil
    }
}
