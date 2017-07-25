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

    override open func serializedRequestWith(request: URLRequest,
                                             bodyParameters: Any? = nil,
                                             queryParameters: [String : Any]? = nil) throws -> URLRequest {

        var mutableRequest = try super.serializedRequestWith(request: request,
                                                             bodyParameters: bodyParameters,
                                                             queryParameters: queryParameters)

        guard let url = mutableRequest.url else {
            throw RequestSerializerError.invalidURL
        }

        if let p = queryParameters {
            let queryString = QueryString(parameters: p, url: url)
            mutableRequest.url = try queryString.encodeURL()
        }

        if let bp = bodyParameters {
            // This URI-encodes `p`, use an empty URL as the base.
            // Then we grab the .query property from the resulting URL
            let queryString = QueryString(parameters: bp, url: url)
            let formEncodedParams = try queryString.encodeURL().query
            mutableRequest.httpBody = formEncodedParams?.data(using: String.Encoding.utf8)
        }

        if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            mutableRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }

        return mutableRequest
    }

}
