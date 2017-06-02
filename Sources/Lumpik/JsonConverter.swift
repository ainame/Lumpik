//
//  JsonConverter.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation

protocol Converter {
    func serialize(_ dictionary: [String: Any]) throws -> String
    
    func serialize(_ array: [Any]) throws -> String
    
    func deserialize(dictionary rawValue: String) throws -> [String: Any]
    
    func deserialize(array rawValue: String) throws -> [Any]
}

public final class JsonConverter: Converter {
    static let defaultWriteOption = JSONSerialization.WritingOptions()
    static let defaultReadOption = JSONSerialization.ReadingOptions()
    
    let writeOption: JSONSerialization.WritingOptions
    let readOption: JSONSerialization.ReadingOptions
    
    static var `default` = JsonConverter(writeOption: JsonConverter.defaultWriteOption, readOption: JsonConverter.defaultReadOption)
    
    init(writeOption: JSONSerialization.WritingOptions, readOption: JSONSerialization.ReadingOptions) {
        self.writeOption = writeOption
        self.readOption = readOption
    }
    
    func serialize(_ dictionary: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: writeOption)
        return String(bytes: data, encoding: .utf8)!
    }
    
    func serialize(_ array: [Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: array, options: writeOption)
        return String(bytes: data, encoding: .utf8)!
    }
    
    func deserialize(dictionary rawValue: String) throws -> [String: Any] {
        let data = rawValue.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: readOption)
        return json as! [String: Any]
    }
    
    func deserialize(array rawValue: String) throws -> [Any] {
        let data = rawValue.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: readOption)
        return json as! [Any]
    }
}
