//
//  Upload.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import Defaults
import Foundation

enum UploadType: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
    case IMGUR, CUSTOM

    var id: Self { self }
}

@MainActor func uploadFile(fileURL: URL, uploadType: UploadType, completion: @Sendable @escaping () -> Void) {
    let activeUploader = Defaults[.activeCustomUploader]

    switch uploadType {
    case .IMGUR:
        imgurUpload(fileURL, completion: completion)
    case .CUSTOM:
        guard let specification = CustomUploader.allCases.first(where: { $0.id == activeUploader }) else {
            print("Custom uploader specification not found")
            completion()
            return
        }
        customUpload(fileURL: fileURL, specification: specification, completion: completion)
    }
}
