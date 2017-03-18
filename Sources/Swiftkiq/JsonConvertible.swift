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
    
    var asDictionary: [String: Any] { get }
    
    var json: String { get }
}

extension JsonConvertible {
    public static var converter: JsonConverter {
        return JsonConverter.default
    }
    
    public var json: String {
        return Self.converter.serialize(asDictionary)
    }
}
