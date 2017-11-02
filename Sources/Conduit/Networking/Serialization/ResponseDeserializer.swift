//
//  ResponseDeserializer.swift
//  Conduit
//
//  Created by John Hammerlund on 7/15/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation

/// A structure that deserializes a provided NSURLResponse and response data into a loose transport object
public protocol ResponseDeserializer {
    /// Deserializes a HTTPURLResponse and response data into a loose transport object
    /// - Parameters:
    ///     - response: The URL response to deserialize and validate against
    ///     - data: The response data
    /// - Throws: A `ResponseDeserializerError` if deserialization is not possible
    /// - Returns: A non-domain specific transport object, such as a Dictionary or an Array
    func deserialize(response: HTTPURLResponse?, data: Data?) throws -> Any

    /// Deserializes unvalidated response data into a loose transport object
    /// - Parameters:
    ///     - data: The response data
    /// - Throws: A `ResponseDeserializerError` if deserialization is not possible
    /// - Returns: A non-domain specific transport object, such as a Dictionary or an Array
    func deserialize(data: Data?) throws -> Any
}

/// A ResponseDeserializer that interacts with responses from an HTTP server
public protocol HTTPResponseDeserializer: ResponseDeserializer {
    /// A range of HTTP status codes that are considered valid (usually 200-299)
    var acceptableStatusCodes: IndexSet { get set }

    /// A range of MIME types that are considered valid in the response "Content-Type" header.
    /// This usually associates directly with the concrete implementations of HTTPResponseDeserializer.
    var acceptableContentTypes: [String]? { get set }
}

extension HTTPResponseDeserializer {

    /// Validates the response against acceptable content types and status codes
    /// - Parameters:
    ///   - response: The HTTPURLResponse to validate against
    ///   - responseObject: The deserialized response data
    public func validate(response: HTTPURLResponse?, responseObject: Any?) throws {
        guard let response = response else {
            throw ConduitError.noResponse(request: nil)
        }

        if acceptableStatusCodes.contains(response.statusCode) == false {
            throw ConduitError.internalFailure(message: "Unnaceptable HTTP Status Code: \(response.statusCode)")
        }

        if let acceptableContentTypes = acceptableContentTypes {
            guard let mimeType = response.mimeType else {
                throw ConduitError.internalFailure(message: "Invalid Mime type")
            }
            guard acceptableContentTypes.contains(mimeType) else {
                throw ConduitError.internalFailure(message: "Unnaceptable Mime type: \(mimeType)")
            }
        }
    }

    public func deserialize(response: HTTPURLResponse?, data: Data?) throws -> Any {
        let responseObject = try deserialize(data: data)
        try validate(response: response, responseObject: responseObject)
        return responseObject
    }
}
