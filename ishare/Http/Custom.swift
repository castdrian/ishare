//
//  Custom.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import Alamofire
import Foundation
import Defaults
import AppKit
import SwiftyJSON

enum CustomUploadError: Error {
    case responseParsing
    case responseRetrieval
}

func customUpload(fileURL: URL, specification: CustomUploader, callback: ((Error?, URL?) -> Void)? = nil, completion: @escaping () -> Void) {
    @Default(.captureFileType) var fileType

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
    
    let fileFormName = fileURL.pathExtension == "mov" ? "video" : "image"
    let mimeType = fileURL.pathExtension == "mov" ? "video/mov" : "image/\(fileType)"

    AF.upload(multipartFormData: { multipartFormData in
        if let formData = specification.formData {
            for (key, value) in formData {
                multipartFormData.append(value.data(using: .utf8)!, withName: key)
            }
        }

        let fileData = try? Data(contentsOf: fileURL)
        multipartFormData.append(fileData!, withName: specification.fileFormName ?? fileFormName, fileName: fileURL.lastPathComponent, mimeType: mimeType)
    }, to: url, method: .post, headers: headers).response { response in
        if let data = response.data {
            let json = JSON(data)
            
            if let nestedValue = getNestedJSONValue(json: json, keyPath: specification.responseProp) {
                if let link = nestedValue.string {
                    print("File uploaded successfully. Link: \(link)")
                    
                    var modifiedLink = link
                    if let url = URL(string: modifiedLink), url.scheme == "http" {
                        modifiedLink = modifiedLink.replacingOccurrences(of: "http://", with: "https://")
                    }
                    
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(modifiedLink, forType: .string)
                    
                    callback?(nil, URL(string: modifiedLink))
                    completion()
                } else {
                    print("Error parsing response or retrieving file link")
                    callback?(CustomUploadError.responseParsing, nil)
                    completion()
                }
            } else {
                print("Error retrieving response data")
                callback?(CustomUploadError.responseRetrieval, nil)
                completion()
            }
        }
    }
}

func getNestedJSONValue(json: JSON, keyPath: String) -> JSON? {
    var nestedJSON: JSON? = json
    let nestedKeys = keyPath.components(separatedBy: ".")

    for key in nestedKeys {
        if let index = key.firstIndex(of: "[") {
            let arrayKey = String(key[..<index])
            let arrayIndex = Int(key[key.index(index, offsetBy: 1)..<key.index(before: key.endIndex)]) ?? 0
            nestedJSON = nestedJSON?[arrayKey][arrayIndex]
        } else {
            nestedJSON = nestedJSON?[key]
        }

        if nestedJSON == nil {
            return nil
        }
    }

    return nestedJSON
}
