//
//  URLSessionClientLogging.swift
//  Conduit
//
//  Created by John Hammerlund on 9/6/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

extension URLSessionClient {

    func log(request: URLRequest, requestID: Int64) {
        let endpoint: String
        if let method = request.httpMethod, let url = request.url {
            endpoint = "\(method) \(url)"
        }
        else {
            endpoint = "<Invalid Method/URL>"
        }
        if logger.level <= .debug {
            logger.debug("[🛫 #\(requestID)] \(endpoint)")
            return
        }

        var verboseLogComponents = ["\n>>>>>>>>>>>>>>> REQUEST #\(requestID) >>>>>>>>>>>>>>>>>>", endpoint]
        if let headers = request.allHTTPHeaderFields,
            !headers.isEmpty {
            let allHeaders = headers.map { "  \($0.key): \($0.value)" }.joined(separator: "\n")
            verboseLogComponents.append("Headers: {\n\(allHeaders)\n}")
        }
        if let body = request.httpBody {
            let bodyString = String(data: body, encoding: .utf8) ?? "<Failed to Parse Body>"
            verboseLogComponents.append("\(bodyString)")
        }
        logger.verbose(verboseLogComponents.joined(separator: "\n"))
    }

    func log(data: Data?, response: HTTPURLResponse?, request: URLRequest, requestID: Int64) {
        let endpoint: String
        if let method = request.httpMethod, let url = request.url {
            endpoint = "\(method) \(url)"
        }
        else {
            endpoint = "<Invalid Method/URL>"
        }
        let statusDescription = makeStatusDescription(code: response?.statusCode)
        let responseEndpointDescription = "\(endpoint) => \(statusDescription)"

        if logger.level <= .debug {
            logger.debug("[🛬 #\(requestID)] \(responseEndpointDescription)")
            return
        }
        var verboseLogComponents = ["\n<<<<<<<<<<<<<< RESPONSE #\(requestID) <<<<<<<<<<<<<<<<<<<<", responseEndpointDescription]

        if let headers = response?.allHeaderFields,
            !headers.isEmpty {
            let allHeaders = headers.map { "  \($0.key): \($0.value)" }.joined(separator: "\n")
            verboseLogComponents.append("Headers: {\n\(allHeaders)\n}")
        }

        if let data = data {
            let bodyString = String(data: data, encoding: .utf8) ?? "<Failed to Parse Response Data>"
            verboseLogComponents.append("\(bodyString)")
        }
        logger.verbose(verboseLogComponents.joined(separator: "\n"))
    }

    private func makeStatusDescription(code: Int?) -> String {
        guard let code = code,
            code > 0 else {
                return "<No Response> 🚫"
        }
        switch code {
        case 200..<300:
            return "\(code) ✅"
        case 300..<400:
            return "\(code) ↪️"
        case 401, 403:
            return "\(code) ⛔️"
        case 400..<500:
            return "\(code) ❌"
        case 500..<Int.max:
            return "\(code) 💥"
        default:
            return "\(code)"
        }
    }

}
