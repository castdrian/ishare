//
//  CustomUploader.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import Foundation
import Defaults

enum RequestBodyType: String, Codable {
    case multipartFormData = "multipartformdata"
    case binary = "binary"
}

struct CustomUploader: Codable, Hashable, Equatable, CaseIterable, Identifiable, Defaults.Serializable {
    var id: UUID
    let name: String
    let requestURL: String
    let headers: [String: String]?
    let formData: [String: String]?
    let fileFormName: String?
    let requestBodyType: RequestBodyType?
    let responseURL: String
    let deletionURL: String?
    
    init(id: UUID = UUID(), name: String, requestURL: String, headers: [String: String]?, formData: [String: String]?, fileFormName: String?, requestBodyType: RequestBodyType? = nil, responseURL: String, deletionURL: String? = nil) {
        self.id = id
        self.name = name
        self.requestURL = requestURL
        self.headers = headers
        self.formData = formData
        self.fileFormName = fileFormName
        self.requestBodyType = requestBodyType
        self.responseURL = responseURL
        self.deletionURL = deletionURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        requestURL = try container.decode(String.self, forKey: .requestURL)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
        formData = try container.decodeIfPresent([String: String].self, forKey: .formData)
        fileFormName = try container.decodeIfPresent(String.self, forKey: .fileFormName)
        requestBodyType = try container.decodeIfPresent(RequestBodyType.self, forKey: .requestBodyType)
        responseURL = try container.decode(String.self, forKey: .responseURL)
        deletionURL = try container.decodeIfPresent(String.self, forKey: .deletionURL)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case requestURL
        case headers
        case formData
        case fileFormName
        case requestBodyType
        case responseURL
        case deletionURL
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
        guard !requestURL.isEmpty, !responseURL.isEmpty else {
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
        
        return true
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }

    static func key(named name: String) -> DynamicCodingKeys {
        return DynamicCodingKeys(stringValue: name)!
    }
}

extension KeyedDecodingContainer {
    func decode<T: Decodable>(_ type: T.Type, forKey key: DynamicCodingKeys) throws -> T {
        let allKeys = self.allKeys.map { $0.stringValue.lowercased() }
        if let matchingKey = allKeys.first(where: { $0.lowercased() == key.stringValue.lowercased() }) {
            let dynamicKey = DynamicCodingKeys(stringValue: matchingKey)!
            return try self.decode(T.self, forKey: dynamicKey)
        } else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "No key found for \(key.stringValue)"))
        }
    }

    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: DynamicCodingKeys) throws -> T? {
        let allKeys = self.allKeys.map { $0.stringValue.lowercased() }
        if let matchingKey = allKeys.first(where: { $0.lowercased() == key.stringValue.lowercased() }) {
            let dynamicKey = DynamicCodingKeys(stringValue: matchingKey)!
            return try self.decodeIfPresent(T.self, forKey: dynamicKey)
        } else {
            return nil
        }
    }
}
