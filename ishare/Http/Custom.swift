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
    let fileName = fileURL.lastPathComponent
    headers.add(name: "x-file-name", value: fileName)
    
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
            let lowercasedFileName = fileNameWithLowercaseExtension(from: fileURL)
            multipartFormData.append(fileData, withName: specification.fileFormName ?? fileFormName, fileName: lowercasedFileName, mimeType: mimeType)
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

func performDeletionRequest(deletionUrl: String, completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: deletionUrl) else {
        completion(.failure(CustomUploadError.responseParsing))
        return
    }

    AF.request(url, method: .get).response { response in
        switch response.result {
        case .success:
            completion(.success("Deleted file successfully"))
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

func handleResponse(data: Data, specification: CustomUploader, callback: ((Error?, URL?) -> Void)?, completion: @escaping () -> Void) {
    let json = JSON(data)
    print(json)
    
    let fileUrl = constructUrl(from: specification.responseURL, using: json)
    let deletionUrl = constructUrl(from: specification.deletionURL, using: json)
    
    // Continue with callback and completion
    if let fileUrl = URL(string: fileUrl) {
        let historyItem = HistoryItem(fileUrl: fileUrl.absoluteString, deletionUrl: deletionUrl)
        addToUploadHistory(historyItem)
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fileUrl.absoluteString, forType: .string)
        callback?(nil, fileUrl)
    } else {
        callback?(CustomUploadError.responseParsing, nil)
    }
    completion()
}

func constructUrl(from format: String?, using json: JSON) -> String {
    guard let format = format else { return "" }
    let (taggedUrl, tags) = tagPlaceholders(in: format)
    var url = taggedUrl

    for (tag, key) in tags {
        if let replacement = json[key].string {
            url = url.replacingOccurrences(of: tag, with: replacement)
        }
    }

    return url
}

func tagPlaceholders(in url: String) -> (taggedUrl: String, tags: [(String, String)]) {
    var taggedUrl = url
    var tags: [(String, String)] = []
    let pattern = "\\{\\{([a-zA-Z0-9_]+)\\}\\}"
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let nsrange = NSRange(url.startIndex..<url.endIndex, in: url)

    regex?.enumerateMatches(in: url, options: [], range: nsrange) { match, _, _ in
        if let match = match, let range = Range(match.range(at: 1), in: url) {
            let key = String(url[range])
            let tag = "%%\(key)_TAG%%"
            tags.append((tag, key))
            taggedUrl = taggedUrl.replacingOccurrences(of: "{{\(key)}}", with: tag)
        }
    }
    return (taggedUrl, tags)
}

func getNestedJSONValue(json: JSON, keyPath: String) -> String? {
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

    return nestedJSON?.stringValue
}

func fileNameWithLowercaseExtension(from url: URL) -> String {
    let fileName = url.deletingPathExtension().lastPathComponent
    let fileExtension = url.pathExtension.lowercased()
    return fileExtension.isEmpty ? fileName : "\(fileName).\(fileExtension)"
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

