//
//  JsonConverter.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation

protocol Converter {
    func serialize(_ dictionary: [String: Any]) -> String
    
    func serialize(_ array: [Any]) -> String
    
    func deserialize(dictionary rawValue: String) -> [String: Any]
    
    func deserialize(array rawValue: String) -> [Any]
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
    
    func serialize(_ dictionary: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: dictionary, options: JsonConverter.defaultWriteOption)
        return String(bytes: data, encoding: .utf8)!
    }
    
    func serialize(_ array: [Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: array, options: JsonConverter.defaultWriteOption)
        return String(bytes: data, encoding: .utf8)!
    }
    
    func deserialize(dictionary rawValue: String) -> [String: Any] {
        let data = rawValue.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data, options: JsonConverter.defaultReadOption)
        return json as! [String: Any]
    }
    
    func deserialize(array rawValue: String) -> [Any] {
        let data = rawValue.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data, options: JsonConverter.defaultReadOption)
        return json as! [Any]
    }
}
