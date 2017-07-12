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

    public init(readingOptions: JSONSerialization.ReadingOptions = []) {
        self.readingOptions = readingOptions
    }

    public func deserializedObjectFrom(response: URLResponse?, data: Data?) throws -> Any {

        guard let data = data, data.isEmpty == false else {
            throw ResponseDeserializerError.noData
        }

        let responseObject = try deserializeObjectFrom(data: data)

        try self.validate(response: response, responseObject: responseObject)

        return responseObject
    }

    private func deserializeObjectFrom(data: Data) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: self.readingOptions)
        }
        catch {
            throw ResponseDeserializerError.deserializationFailure
        }
    }
}
