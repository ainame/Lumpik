//
//  JsonConvertible.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation
import Mapper

public protocol JsonConvertible: Mappable {
    static var converter: JsonConverter { get }

    static func from(_ JSON: String) -> Self?
    
    var asDictionary: [String: Any] { get }
    
    var json: String { get }
}

extension JsonConvertible {
    public static func from(_ JSON: String) -> Self? {
        let map: NSDictionary = converter.deserialize(dictionary: JSON) as NSDictionary
        return from(map)
    }
    
    public static var converter: JsonConverter {
        return JsonConverter.default
    }
    
    public var json: String {
        return Self.converter.serialize(asDictionary)
    }
}
