//
//  XMLRequestSerializer.swift
//  Conduit
//
//  Created by John Hammerlund on 12/16/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An HTTPRequestSerializer that serializes request content into XML data
public final class XMLRequestSerializer: HTTPRequestSerializer {

    public override init() {}

    public override func serialize(request: URLRequest, bodyParameters: Any? = nil) throws -> URLRequest {
        var request: URLRequest = try super.serialize(request: request, bodyParameters: bodyParameters)
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        if let bodyData: Data = try bodyData(bodyParameters: bodyParameters) {
            request.setValue(String(bodyData.count), forHTTPHeaderField: "Content-Length")
            request.httpBody = bodyData
        }

        return request
    }

    private func bodyData(bodyParameters: Any? = nil) throws -> Data? {
        var bodyData: Data? = nil
        if bodyParameters != nil {
            guard let bodyParameters = bodyParameters as? XML else {
                throw ConduitError.serializationError(message: "Missing body data")
            }
            let bodyString = String(describing: bodyParameters)
            bodyData = bodyString.data(using: .utf8)
            guard bodyData != nil else {
                throw ConduitError.serializationError(message: "Failed to encode body data")
            }
        }
        return bodyData
    }

}
