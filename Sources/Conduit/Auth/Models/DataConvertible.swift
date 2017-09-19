//
//  DataConvertible.swift
//  Conduit
//
//  Created by John Hammerlund on 8/17/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// A type that can be serialized and deserialized with arbitrary encoding
public protocol DataConvertible {
    /// Serializes the structure with arbitrary encoding
    func serialized() -> Data?

    /// Deserializes the structure with encoding defined by `serialized()`
    /// - Parameters:
    ///    - serializedData: The data to deserialize
    init?(serializedData: Data)
}

extension DataConvertible where Self: Encodable {

    public func serialized() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }

}

extension DataConvertible where Self: Decodable {

    public init?(serializedData: Data) {
        let decoder = JSONDecoder()
        guard let deserialized = try? decoder.decode(Self.self, from: serializedData) else {
            return nil
        }
        self = deserialized
    }

}

extension DataConvertible where Self: NSCoding {

    public func serialized() -> Data? {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }

    public init?(serializedData: Data) {
        guard let deserialized = NSKeyedUnarchiver.unarchiveObject(with: serializedData) as? Self else {
            return nil
        }
        self = deserialized
    }
}
