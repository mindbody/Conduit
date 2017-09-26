//
//  LastLog.swift
//  Conduit
//
//  Created by Bart Powers on 9/26/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

public struct LastLog {
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
        if let requestBody = request.httpBody {
            let bodyString = String(data: requestBody, encoding: .utf8) ?? "<Failed to Parse Body>"
            body = bodyString
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
            let bodyString = String(data: data, encoding: .utf8) ?? "<Failed to Parse Response Data>"
            body = bodyString
        }
    }
}
