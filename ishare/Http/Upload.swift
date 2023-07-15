//
//  Upload.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import Foundation
import Defaults

enum UploadType: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
    case IMGUR, CUSTOM
    var id: Self { self }
}

func uploadFile(fileURL: URL, uploadType: UploadType, completion: @escaping () -> Void) {
    @Default(.activeCustomUploader) var activeUploader
    
    switch uploadType {
    case .IMGUR:
        imgurUpload(fileURL, completion: completion)
    case .CUSTOM:
        guard let specification = activeUploader else {
            print("Custom uploader specification not found")
            completion()
            return
        }
        customUpload(fileURL: fileURL, specification: specification, completion: completion)
    }
}
