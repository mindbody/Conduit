//
//  JSONResponseDeserializer.swift
//  Conduit
//
//  Created by John Hammerlund on 7/15/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation

/// An HTTPResponseDeserializer that deals with JSON responses
public final class JSONResponseDeserializer: HTTPResponseDeserializer {

    public let readingOptions: JSONSerialization.ReadingOptions
    public var acceptableStatusCodes: IndexSet = IndexSet(integersIn: 200..<300)
    public var acceptableContentTypes: [String]? = ["application/json"]

    /// Creates a new JSONResponseDeserializer
    /// - Parameters:
    ///   - readingOptions: (Optional) A list of reading options for JSON deserialization
    public init(readingOptions: JSONSerialization.ReadingOptions = []) {
        self.readingOptions = readingOptions
    }

    public func deserialize(data optionalData: Data?) throws -> Any {
        guard let data = optionalData, data.isEmpty == false else {
            throw ConduitError.deserializationError(data: optionalData, type: Any.self)
        }

        return try deserializeObjectFrom(data: data)
    }

    private func deserializeObjectFrom(data: Data) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: readingOptions)
        }
        catch {
            throw ConduitError.deserializationError(data: data, type: Any.self)
        }
    }
}
