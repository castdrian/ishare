//
//  Custom.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import Alamofire
import Foundation
import AppKit

func customUpload(fileURL: URL, specification: CustomUploader, completion: @escaping () -> Void) {
    guard specification.isValid() else {
        print("Invalid specification")
        completion()
        return
    }
    
    let url = specification.requestUrl
    var headers: HTTPHeaders?
    
    if let requestHeaders = specification.headers {
        headers = HTTPHeaders(requestHeaders)
    }
    
    AF.upload(multipartFormData: { multipartFormData in
        if let formData = specification.formData {
            for (key, value) in formData {
                multipartFormData.append(value.data(using: .utf8)!, withName: key)
            }
        }
        
        let fileData = try? Data(contentsOf: fileURL)
        multipartFormData.append(fileData!, withName: "image", fileName: fileURL.lastPathComponent)
    }, to: url, method: .post, headers: headers).response { response in
        if let data = response.data,
           let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
           let link = json[specification.responseProp] as? String {
            print("File uploaded successfully. Link: \(link)")

            var modifiedLink = link
            if let url = URL(string: modifiedLink), url.scheme == "http" {
                modifiedLink = modifiedLink.replacingOccurrences(of: "http://", with: "https://")
            }

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(modifiedLink, forType: .string)

            completion()
        } else {
            print("Error parsing response or retrieving file link")
            completion()
        }
    }
}
