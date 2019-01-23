//
//  FormEncodedRequestSerializer.swift
//  Conduit
//
//  Created by Matthew Holden on 8/16/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An HTTPRequestSerialzer that url-encodes body parameters
public final class FormEncodedRequestSerializer: HTTPRequestSerializer {

    public override init() {}

    /// Defines how parameters should be encoded within the HTTP body.
    public var formattingOptions = QueryStringFormattingOptions()

    override public func serialize(request: URLRequest, bodyParameters: Any? = nil) throws -> URLRequest {

        var mutableRequest = try super.serialize(request: request, bodyParameters: bodyParameters)

        guard let url = mutableRequest.url else {
            throw RequestSerializerError.invalidURL
        }

        if let bodyParameters = bodyParameters {
            // This URI-encodes `p`, use an empty URL as the base.
            // Then we grab the .query property from the resulting URL
            var queryString = QueryString(parameters: bodyParameters, url: url)
            queryString.formattingOptions = formattingOptions
            let formEncodedParams = try queryString.encodeURL().query
            mutableRequest.httpBody = formEncodedParams?.data(using: String.Encoding.utf8)
        }

        return mutableRequest
    }

}
