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
    /// Deserializes an NSURLResponse and response data into a loose transport object
    /// - Parameters:
    ///     - response: The URL response to deserialize and validate against
    ///     - data: The response data
    /// - Throws: A `ResponseDeserializerError` if deserialization is not possible
    /// - Returns: A non-domain specific transport object, such as a Dictionary or an Array
    func deserializedObjectFrom(response: URLResponse?, data: Data?) throws -> Any
}

/// A ResponseDeserializer that interacts with responses from an HTTP server
public protocol HTTPResponseDeserializer: ResponseDeserializer {
    /// A range of HTTP status codes that are considered valid (usually 200-299)
    var acceptableStatusCodes: IndexSet { get set }

    /// A range of MIME types that are considered valid in the response "Content-Type" header.
    /// This usually associates directly with the concrete implementations of HTTPResponseDeserializer.
    var acceptableContentTypes: [String]? { get set }
}

/// Errors that signify failures within `ResponseDeserializer`
/// - Unknown: Deserialization could not be completed due to an unexpected error
/// - NoResponse: No response was provided, or the response was empty
/// - BadResponse: The response is not valid or indicates a failure
/// - NoData: No response data was provided, or the data is empty
/// - SerializationFailure: The response data could not be deserialized
public enum ResponseDeserializerError: Error {
    case unknown
    case noResponse
    case badResponse(responseObject: Any?)
    case noData
    case deserializationFailure
}

public extension HTTPResponseDeserializer {
    public func validate(response: URLResponse?, responseObject: Any?) throws {
        guard let response = response as? HTTPURLResponse else {
            throw ResponseDeserializerError.noResponse
        }

        if !self.acceptableStatusCodes.contains(response.statusCode) {
            throw ResponseDeserializerError.badResponse(responseObject: responseObject)
        }

        if let acceptableContentTypes = self.acceptableContentTypes {
            guard let mimeType = response.mimeType, acceptableContentTypes.contains(mimeType) else {
                throw ResponseDeserializerError.badResponse(responseObject: responseObject)
            }
        }
    }
}
