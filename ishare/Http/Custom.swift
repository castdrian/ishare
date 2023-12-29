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
    case fileReadError
}

func customUpload(fileURL: URL, specification: CustomUploader, callback: ((Error?, URL?) -> Void)? = nil, completion: @escaping () -> Void) {
    @Default(.captureFileType) var fileType

    guard specification.isValid() else {
        print("Invalid specification")
        completion()
        return
    }

    let url = URL(string: specification.requestUrl)!
    var headers = HTTPHeaders(specification.headers ?? [:])

    switch specification.requestBodyType {
    case .multipartFormData, .none:
        uploadMultipartFormData(fileURL: fileURL, url: url, headers: headers, specification: specification, callback: callback, completion: completion)

    case .binary:
        uploadBinaryData(fileURL: fileURL, url: url, headers: &headers, specification: specification, callback: callback, completion: completion)
    }
}

func uploadMultipartFormData(fileURL: URL, url: URL, headers: HTTPHeaders, specification: CustomUploader, callback: ((Error?, URL?) -> Void)?, completion: @escaping () -> Void) {
    var fileFormName: String
    var mimeType: String

    switch fileURL.pathExtension {
    case "mp4":
        fileFormName = "video"
        mimeType = "video/mp4"
    case "mov":
        fileFormName = "video"
        mimeType = "video/mov"
    default:
        fileFormName = "image"
        mimeType = "image/\(fileURL.pathExtension)"
    }

    AF.upload(multipartFormData: { multipartFormData in
        if let formData = specification.formData {
            for (key, value) in formData {
                multipartFormData.append(value.data(using: .utf8)!, withName: key)
            }
        }

        if let fileData = try? Data(contentsOf: fileURL) {
            multipartFormData.append(fileData, withName: specification.fileFormName ?? fileFormName, fileName: fileURL.lastPathComponent, mimeType: mimeType)
        }
    }, to: url, method: .post, headers: headers).response { response in
        if let data = response.data {
            handleResponse(data: data, specification: specification, callback: callback, completion: completion)
        } else {
            callback?(CustomUploadError.responseRetrieval, nil)
            completion()
        }
    }
}

func uploadBinaryData(fileURL: URL, url: URL, headers: inout HTTPHeaders, specification: CustomUploader, callback: ((Error?, URL?) -> Void)?, completion: @escaping () -> Void) {
    guard let fileData = try? Data(contentsOf: fileURL) else {
        callback?(CustomUploadError.fileReadError, nil)
        completion()
        return
    }

    let mimeType = mimeTypeForPathExtension(fileURL.pathExtension)
    headers.add(name: "Content-Type", value: mimeType)

    AF.upload(fileData, to: url, method: .post, headers: headers).response { response in
        if let data = response.data {
            handleResponse(data: data, specification: specification, callback: callback, completion: completion)
        } else {
            callback?(CustomUploadError.responseRetrieval, nil)
            completion()
        }
    }
}

func handleResponse(data: Data, specification: CustomUploader, callback: ((Error?, URL?) -> Void)?, completion: @escaping () -> Void) {
    let json = JSON(data)
    if let nestedValue = getNestedJSONValue(json: json, keyPath: specification.responseProp) {
        if let link = nestedValue.string {
            print("File uploaded successfully. Link: \(link)")
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(link, forType: .string)
            addToUploadHistory(link)
            callback?(nil, URL(string: link))
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

func mimeTypeForPathExtension(_ ext: String) -> String {
    switch ext.lowercased() {
    case "jpg", "jpeg":
        return "image/jpeg"
    case "png":
        return "image/png"
    case "gif":
        return "image/gif"
    case "pdf":
        return "application/pdf"
    case "mp4":
        return "video/mp4"
    case "mov":
        return "video/quicktime"
    default:
        return "application/octet-stream"
    }
}

