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
    
    enum CodingKeys: String, CodingKey {
            case id
            case name
            case requestURL = "requesturl"
            case headers
            case formData = "formdata"
            case fileFormName = "fileformname"
            case requestBodyType = "requestbodytype"
            case responseURL = "responseurl"
            case deletionURL = "deletionurl"
        }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        id = try container.decodeDynamicIfPresent(UUID.self, forKey: DynamicCodingKey(stringValue: "id")!) ?? UUID()
        name = try container.decodeDynamic(String.self, forKey: DynamicCodingKey(stringValue: "name")!)
        requestURL = try container.decodeDynamic(String.self, forKey: DynamicCodingKey(stringValue: "requesturl")!)
        headers = try container.decodeDynamicIfPresent([String: String].self, forKey: DynamicCodingKey(stringValue: "headers")!)
        formData = try container.decodeDynamicIfPresent([String: String].self, forKey: DynamicCodingKey(stringValue: "formdata")!)
        fileFormName = try container.decodeDynamicIfPresent(String.self, forKey: DynamicCodingKey(stringValue: "fileformname")!)
        requestBodyType = try container.decodeDynamicIfPresent(RequestBodyType.self, forKey: DynamicCodingKey(stringValue: "requestbodytype")!)
        responseURL = try container.decodeDynamic(String.self, forKey: DynamicCodingKey(stringValue: "responseurl")!)
        deletionURL = try container.decodeDynamicIfPresent(String.self, forKey: DynamicCodingKey(stringValue: "deletionurl")!)
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
        // Convert JSON data to a dictionary
        guard let jsonObject = try JSONSerialization.jsonObject(with: json, options: []) as? [String: Any] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON structure"))
        }

        // Convert all keys in the dictionary to lowercase
        let lowercasedKeysJsonObject = jsonObject.reduce(into: [String: Any]()) { (result, element) in
            result[element.key.lowercased()] = element.value
        }

        // Encode the modified dictionary back to Data
        let modifiedJsonData = try JSONSerialization.data(withJSONObject: lowercasedKeysJsonObject, options: [])

        // Decode using the modified JSON data
        let decoder = JSONDecoder()
        return try decoder.decode(CustomUploader.self, from: modifiedJsonData)
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

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }

    static func key(named name: String) -> DynamicCodingKey {
        return DynamicCodingKey(stringValue: name)!
    }
}

extension KeyedDecodingContainer {
    func decodeDynamic<T: Decodable>(_ type: T.Type, forKey key: DynamicCodingKey) throws -> T {
        let keyString = key.stringValue.lowercased()
        guard let dynamicKey = allKeys.first(where: { $0.stringValue.lowercased() == keyString }) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(keyString)"))
        }
        return try self.decode(T.self, forKey: dynamicKey)
    }

    func decodeDynamicIfPresent<T: Decodable>(_ type: T.Type, forKey key: DynamicCodingKey) throws -> T? {
        let keyString = key.stringValue.lowercased()
        guard let dynamicKey = allKeys.first(where: { $0.stringValue.lowercased() == keyString }) else {
            return nil
        }
        return try self.decodeIfPresent(T.self, forKey: dynamicKey)
    }
}
