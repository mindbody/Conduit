//
//  DataConvertible.swift
//  Conduit
//
//  Created by John Hammerlund on 8/17/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

public protocol DataConvertible {
    func serialize() -> Data?
    init?(serializedData: Data)
}

extension DataConvertible where Self: Encodable {

    public func serialize() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }

}

extension DataConvertible where Self: Decodable {

    public init?(serializedData: Data) {
        let decoder = JSONDecoder()
        guard let deserialzed = try? decoder.decode(Self.self, from: serializedData) else {
            return nil
        }
        self = deserialzed
    }

}

extension DataConvertible where Self: NSCoding {

    public func serialize() -> Data? {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }

    public init?(serializedData: Data) {
        guard let deserialized = NSKeyedUnarchiver.unarchiveObject(with: serializedData) as? Self else {
            return nil
        }
        self = deserialized
    }
}
