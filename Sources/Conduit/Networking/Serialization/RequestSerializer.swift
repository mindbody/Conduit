//
//  RequestSerializer.swift
//  Conduit
//
//  Created by John Hammerlund on 7/15/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation

/// A structure that serializes a provided URLRequest and parameters for transport
public protocol RequestSerializer {
    /// Serializes a request for transport based on the concrete structure's desired MIME type
    /// - Parameters:
    ///     - request: The non-parameterized request to serialize
    ///     - bodyParameters: Parameters to serialize into the HTTP Body
    ///     - queryParameters: Parameters to URI-encode into the request URL's query.
    /// - Throws: A `RequestSerializerError` if serialization is not possible
    /// - Returns: A serialized URLRequest
    func serializedRequestWith(request: URLRequest, bodyParameters: Any?,
                               queryParameters: [String: Any]?) throws -> URLRequest
}

/// Errors that signify failures within a `RequestSerializer`
public enum RequestSerializerError: Error {
    /// Serialization could not be completed due to an unexpected error
    case unknown
    /// The serializer was asked to serialize "body parameters," but
    /// the specified HTTP verb does not submit a body (i.e. GET and HEAD)
    case httpVerbDoesNotAllowBodyParameters
    /// Something went wrong when attempting to serialize the request
    case serializationFailure
    /// Invalid URL
    case invalidURL
}
