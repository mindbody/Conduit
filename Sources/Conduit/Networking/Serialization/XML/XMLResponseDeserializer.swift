//
//  XMLResponseDeserializer.swift
//  Conduit
//
//  Created by John Hammerlund on 12/16/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An HTTPResponseDeserializer that deals with XML responses
public final class XMLResponseDeserializer: HTTPResponseDeserializer {
    /// A range of MIME types that are considered valid in the response "Content-Type" header.
    /// This usually associates directly with the concrete implementations of HTTPResponseDeserializer.
    public var acceptableContentTypes: [String]?

    /// A range of HTTP status codes that are considered valid (usually 200-299)
    public var acceptableStatusCodes = IndexSet(integersIn: 200..<300)

    public init() {}

    public func deserializedObjectFrom(response: URLResponse?, data: Data?) throws -> Any {

        guard let data = data, data.isEmpty == false else {
            throw ResponseDeserializerError.noData
        }

        let responseObject = try deserializeObjectFrom(data: data)

        try self.validate(response: response, responseObject: responseObject)

        return responseObject
    }

    public func deserializeObjectFrom(data: Data) throws -> Any {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw ResponseDeserializerError.deserializationFailure
        }
        if let xml = XML(xmlString: xmlString) {
            return xml
        }
        throw ResponseDeserializerError.deserializationFailure
    }

}
