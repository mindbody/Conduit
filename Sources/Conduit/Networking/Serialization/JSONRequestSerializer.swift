//
//  JSONRequestSerializer.swift
//  Conduit
//
//  Created by John Hammerlund on 7/15/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation

/// An HTTPRequestSerializer that serializes request content into JSON data
public final class JSONRequestSerializer: HTTPRequestSerializer {

    let writingOptions: JSONSerialization.WritingOptions

    /// Creates a new JSONRequestSerializer
    /// - Parameters:
    ///   - writingOptions: (Optional) A list of writing options for JSON serialization
    public init(writingOptions: JSONSerialization.WritingOptions = []) {
        self.writingOptions = writingOptions
        super.init()
    }

    public override func serialize(request: URLRequest, bodyParameters: Any? = nil) throws -> URLRequest {
        var request = try super.serialize(request: request, bodyParameters: bodyParameters)

        var JSONData: Data? = nil
        if let bp = bodyParameters {
            do {
                if let fragmentData = JSONRequestSerializer.fragmentedDataFrom(jsonObject: bp) {
                    JSONData = fragmentData
                }
                else {
                    try JSONData = JSONSerialization.data(withJSONObject: bp, options: writingOptions)
                }
            }
            catch let error {
                throw ConduitError.serializationError(message: error.localizedDescription)
            }
        }

        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let JSONData = JSONData {
            request.setValue(String(JSONData.count), forHTTPHeaderField: "Content-Length")
            request.httpBody = JSONData
        }

        return request
    }

    static func fragmentedDataFrom(jsonObject: Any?) -> Data? {
        var bodyString: String?
        if let number = jsonObject as? NSNumber {
            bodyString = String(describing: number)
        }
        else if let string = jsonObject as? String {
            bodyString = "\"\(string)\""
        }
        else if jsonObject is NSNull {
            bodyString = "null"
        }

        if let bodyString = bodyString {
            return bodyString.data(using: String.Encoding.utf8)
        }
        return nil
    }
}
