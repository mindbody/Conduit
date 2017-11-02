//
//  RequestSerializer.swift
//  Conduit
//
//  Created by John Hammerlund on 7/15/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation

/// A structure that serializes a provided URLRequest and body parameters for transport
public protocol RequestSerializer {
    /// Serializes a request for transport based on the concrete structure's desired MIME type
    /// - Parameters:
    ///     - request: The non-parameterized request to serialize
    ///     - bodyParameters: Parameters to serialize into the HTTP Body
    /// - Throws: A `RequestSerializerError` if serialization is not possible
    /// - Returns: A serialized URLRequest
    func serialize(request: URLRequest, bodyParameters: Any?) throws -> URLRequest
}
