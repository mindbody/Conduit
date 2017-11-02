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
    func serialized() throws -> Data

    /// Deserializes the structure with encoding defined by `serialized()`
    /// - Parameters:
    ///    - serializedData: The data to deserialize
    init(serializedData: Data) throws
}

extension DataConvertible where Self: Encodable {

    public func serialized() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }

}

extension DataConvertible where Self: Decodable {

    public init(serializedData: Data) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: serializedData)
    }

}

extension DataConvertible where Self: NSCoding {

    public func serialized() throws -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }

    public init(serializedData data: Data) throws {
        guard let deserialized = NSKeyedUnarchiver.unarchiveObject(with: data) as? Self else {
            throw ConduitError.deserializationError(data: data, type: Self.self)
        }
        self = deserialized
    }
}
