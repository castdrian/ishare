//
//  CustomUploader.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import Foundation
import Defaults

struct CustomUploader: Codable, Hashable, Identifiable, Defaults.Serializable {
    var id: UUID = UUID()
    let name: String
    let requestUrl: String
    let headers: [String: String]?
    let formData: [String: String]?
    let responseProp: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case requestUrl
        case headers
        case formData
        case responseProp
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
        
        guard !responseProp.isEmpty else {
            return false
        }
        
        return true
    }
}
