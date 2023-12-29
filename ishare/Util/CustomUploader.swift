//
//  CustomUploader.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import Foundation
import Defaults

enum RequestBodyType: String, Codable {
    case multipartFormData = "multipartFormData"
    case binary = "binary"
}

struct CustomUploader: Codable, Hashable, Equatable, CaseIterable, Identifiable, Defaults.Serializable {
    var id: UUID
    let name: String
    let requestUrl: String
    let headers: [String: String]?
    let formData: [String: String]?
    let fileFormName: String?
    let responseProp: String
    let requestBodyType: RequestBodyType?

    init(id: UUID = UUID(), name: String, requestUrl: String, headers: [String: String]?, formData: [String: String]?, fileFormName: String?, responseProp: String, requestBodyType: RequestBodyType? = nil) {
        self.id = id
        self.name = name
        self.requestUrl = requestUrl
        self.headers = headers
        self.formData = formData
        self.fileFormName = fileFormName
        self.responseProp = responseProp
        self.requestBodyType = requestBodyType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        requestUrl = try container.decode(String.self, forKey: .requestUrl)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
        formData = try container.decodeIfPresent([String: String].self, forKey: .formData)
        fileFormName = try container.decodeIfPresent(String.self, forKey: .fileFormName)
        responseProp = try container.decode(String.self, forKey: .responseProp)
        requestBodyType = try container.decodeIfPresent(RequestBodyType.self, forKey: .requestBodyType)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case requestUrl
        case headers
        case formData
        case fileFormName
        case responseProp
        case requestBodyType
    }
    
    static var allCases: [CustomUploader] {
        return Defaults[.savedCustomUploaders]?.sorted(by: { $0.name < $1.name }) ?? []
    }
    
    static func == (lhs: CustomUploader, rhs: CustomUploader) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func fromJSON(_ json: Data) throws -> CustomUploader {
        let decoder = JSONDecoder()
        return try decoder.decode(CustomUploader.self, from: json)
    }
    
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    func isValid() -> Bool {
        guard !requestUrl.isEmpty else {
            return false
        }
        
        if let headers = headers {
            guard headers as Codable is [String: String] else {
                return false
            }
        }
        
        if let formData = formData {
            guard formData as Codable is [String: String] else {
                return false
            }
        }
        
        if let fileFormName = fileFormName {
            guard !fileFormName.isEmpty else {
                return false
            }
        }
        
        guard !responseProp.isEmpty else {
            return false
        }
        
        return true
    }
}
