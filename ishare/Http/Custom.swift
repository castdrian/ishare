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
    
    let url = URL(string: specification.requestURL)!
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
    AF.upload(multipartFormData: { multipartFormData in
        if let formData = specification.formData {
            for (key, value) in formData {
                multipartFormData.append(value.data(using: .utf8)!, withName: key)
            }
        }

        let mimeType = mimeTypeForPathExtension(fileURL.pathExtension)
        let lowercasedFileName = fileNameWithLowercaseExtension(from: fileURL)
        multipartFormData.append(fileURL, withName: specification.fileFormName ?? "file", fileName: lowercasedFileName, mimeType: mimeType)

    }, to: url, method: .post, headers: headers)
    .uploadProgress { progress in
        UploadManager.shared.updateProgress(fraction: progress.fractionCompleted)
    }
    .response { response in
        UploadManager.shared.uploadCompleted()
        if let data = response.data {
            handleResponse(data: data, specification: specification, callback: callback, completion: completion)
        } else {
            callback?(CustomUploadError.responseRetrieval, nil)
            completion()
        }
    }
}

func uploadBinaryData(fileURL: URL, url: URL, headers: inout HTTPHeaders, specification: CustomUploader, callback: ((Error?, URL?) -> Void)?, completion: @escaping () -> Void) {
    let mimeType = mimeTypeForPathExtension(fileURL.pathExtension)
    headers.add(name: "Content-Type", value: mimeType)

    AF.upload(fileURL, to: url, method: .post, headers: headers)
        .uploadProgress { progress in
            UploadManager.shared.updateProgress(fraction: progress.fractionCompleted)
        }
        .response { response in
            UploadManager.shared.uploadCompleted()
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
    
    @Default(.activeCustomUploader) var activeCustomUploader
    let uploader = CustomUploader.allCases.first(where: { $0.id == activeCustomUploader })
    let headers = HTTPHeaders(uploader?.headers ?? [:])

    func sendRequest(with method: HTTPMethod) {
        AF.request(url, method: method, headers: headers).response { response in
            switch response.result {
            case .success:
                completion(.success("Deleted file successfully"))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    switch uploader?.deleteRequestType {
    case .GET:
        sendRequest(with: .get)
    case .DELETE:
        sendRequest(with: .delete)
    case nil:
        sendRequest(with: .get)
    }
}

func handleResponse(data: Data, specification: CustomUploader, callback: ((Error?, URL?) -> Void)?, completion: @escaping () -> Void) {
    let json = JSON(data)
    
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
    
    for (tag, keyPath) in tags {
        if let replacement = getNestedJSONValue(json: json, keyPath: keyPath) {
            url = url.replacingOccurrences(of: tag, with: replacement)
        }
    }
    
    return url
}

func tagPlaceholders(in url: String) -> (taggedUrl: String, tags: [(String, String)]) {
    var taggedUrl = url
    var tags: [(String, String)] = []
    
    let pattern = "\\{\\{([a-zA-Z0-9_]+(\\[[0-9]+\\])?)\\}\\}"
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
    var currentJSON = json
    let keyPathElements = keyPath.components(separatedBy: ".")
    
    for element in keyPathElements {
        // Splitting the element to handle nested arrays and objects
        let subElements = element.split(whereSeparator: { $0 == "[" || $0 == "]" }).map(String.init)
        
        for subElement in subElements {
            if let index = Int(subElement) {
                // Access array by index
                currentJSON = currentJSON[index]
            } else {
                // Access object by key
                currentJSON = currentJSON[subElement]
            }
        }
        
        // Check if the JSON element is valid
        if currentJSON == JSON.null {
            return "failed to extract json value for \(element)"
        }
    }
    
    return currentJSON.stringValue
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

