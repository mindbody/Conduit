//
//  RequestBuilder.swift
//  Conduit
//
//  Created by Matthew Holden on 7/29/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// A 'builder' object used to construct `URLRequest`s for
/// use over HTTP. By setting a serializer and parameters dictionary,
/// the body (or querystring) for the request can easily be serialized
/// into the right format (i.e. JSON in a POST body, or uri-encoded parameters
/// in a GET request).
public final class HTTPRequestBuilder {

    /// An HTTP request method
    public enum Method: String {
        /// Establishes an in initial HTTP tunnel
        case CONNECT
        /// Deletes a resource
        case DELETE
        /// Fetches a resource
        case GET
        /// Similar to GET, but without response data
        case HEAD
        /// Requests communication options / server capabilities
        case OPTIONS
        /// Updates an existing resource
        case PATCH
        /// Submits a new resource
        case POST
        /// Adds or replaces an existing resource
        case PUT
        /// Initiates a simple server loopback
        case TRACE
    }

    // MARK: Properties

    /// The generated request's URL
    public var url: URL

    /// An optional array of HTTP Headers to apply to the request
    public var headers: [String: String]?

    // Objc and non-objc versions of the `method` property exposed below.

    /// HTTP Method for the generated request
    /// - Note: Defaults to "GET"
    public var method: Method = .GET

    /// The serializer used to serialize the generated request's parameters.
    /// - Note: Defaults to JSONRequestSerializer
    public var serializer: RequestSerializer = JSONRequestSerializer()

    /// Parameters applied to the request. They will be serialized into the request
    /// using the RequestSerializer set on the `requestSerializer` property.
    public var bodyParameters: Any?

    /// Parameters to encoded in the request URL's query string.
    /// - remark: This is designed with for use with POST requests
    /// that accept all or some of its parameters in the URL, instead of
    /// exclusively in the HTTP Body.
    public var queryStringParameters: [String: Any]?

    /// Formatting options for non-standard query string data types
    public var queryStringFormattingOptions = QueryStringFormattingOptions()

    /// A pre-encoded query subcomponent.
    ///
    /// - Note: If percentEncodedQuery is set, then queryStringParameters
    /// are completely ignored when building the request.
    public var percentEncodedQuery: String?

    // MARK: Initialization

    /// Creates a new HTTPRequestBuilder
    /// - Parameters:
    ///   - url: The base URL at which the request is targeted
    public init(url: URL) {
        self.url = url
    }

    // MARK: Methods

    /// Constructs an URLRequest from the builder's assigned properties.
    public func build() throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let headers = self.headers {
            for header in headers {
                request.setValue(header.1, forHTTPHeaderField: header.0)
            }
        }

        request = try serializer.serialize(request: request, bodyParameters: bodyParameters)
        if let url = request.url {
            if let percentEncodedQuery = percentEncodedQuery {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                urlComponents?.percentEncodedQuery = percentEncodedQuery
                request.url = urlComponents?.url ?? url
            }
            else {
                var queryString = QueryString(parameters: queryStringParameters, url: url)
                queryString.formattingOptions = queryStringFormattingOptions
                request.url = try queryString.encodeURL()
            }
        }
        return request
    }

}
