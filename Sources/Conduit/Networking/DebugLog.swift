//
//  DebugLog.swift
//  Conduit
//
//  Created by Bart Powers on 9/26/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

public struct DebugLog {
    var url: String
    var requestLog: RequestLog
    var responseLog: ResponseLog

    init (endpoint: String, data: Data?, response: HTTPURLResponse?, request: URLRequest) {
        url = endpoint
        requestLog = RequestLog(request: request)
        responseLog = ResponseLog(data: data, response: response)
    }
}

struct RequestLog {
    var headers: String?
    var body: String?

    init (request: URLRequest) {
        if let requestHeaders = request.allHTTPHeaderFields,
            !requestHeaders.isEmpty {
            let allHeaders = requestHeaders.map { "  \($0.key): \($0.value)" }.joined(separator: "\n")
            headers = "Headers: {\n\(allHeaders)\n}"
        }
        if let data = request.httpBody {
            body = prettyPrintBody(data: data)
        }
    }
}

struct ResponseLog {
    var status: String?
    var headers: String?
    var body: String?

    init (data: Data?, response: HTTPURLResponse?) {
        status = URLSessionClient().makeStatusDescription(code: response?.statusCode)
        if let responseHeaders = response?.allHeaderFields,
            !responseHeaders.isEmpty {
            let allHeaders = responseHeaders.map { "  \($0.key): \($0.value)" }.joined(separator: "\n")
            headers = "Headers: {\n\(allHeaders)\n}"
        }

        if let data = data {
            body = prettyPrintBody(data: data)
        }
    }
}

private func prettyPrintBody(data: Data) -> String {
    var prettyPrintedData = ""
    if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) {
            if let string = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) {
                prettyPrintedData = "Body: \n \(string as String)"
            }
        }
    }
    else {
        prettyPrintedData = String(data: data, encoding: .utf8) ?? "<Failed to Parse Response Data>"
    }
    return prettyPrintedData
}
