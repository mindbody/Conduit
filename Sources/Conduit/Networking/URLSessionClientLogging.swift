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
        let endpoint = self.endpoint(from: request)
        if logger.level < .verbose {
            logger.debug("[🛫 #\(requestID)] \(endpoint)")
            return
        }

        var verboseLogComponents: [String] = [
            "\n>>>>>>>>>>>>>>> REQUEST #\(requestID) >>>>>>>>>>>>>>>>>>",
            endpoint
        ]
        if let headers = prettyHeaders(headers: request.allHTTPHeaderFields) {
            verboseLogComponents.append(headers)
        }
        if let body = request.httpBody {
            let bodyString = String(data: body, encoding: .utf8) ?? "<Failed to Parse Body>"
            verboseLogComponents.append("\(bodyString)")
        }
        let output: String = verboseLogComponents.joined(separator: "\n")
        logger.verbose(output)
    }

    func log(data: Data?, response: HTTPURLResponse?, request: URLRequest, requestID: Int64) {
        let endpoint = self.endpoint(from: request)
        let statusDescription = makeStatusDescription(code: response?.statusCode)
        let responseEndpointDescription = "\(endpoint) => \(statusDescription)"

        if logger.level < .verbose {
            logger.debug("[🛬 #\(requestID)] \(responseEndpointDescription)")
            return
        }

        var verboseLogComponents = ["\n<<<<<<<<<<<<<< RESPONSE #\(requestID) <<<<<<<<<<<<<<<<<<<<", responseEndpointDescription]

        if let headers = prettyHeaders(headers: response?.allHeaderFields as? [String: String]) {
            verboseLogComponents.append(headers)
        }
        if let data = data {
            let bodyString = String(data: data, encoding: .utf8) ?? "<Failed to Parse Response Data>"
            verboseLogComponents.append("\(bodyString)")
        }
        logger.verbose(verboseLogComponents.joined(separator: "\n"))
    }

    private func endpoint(from request: URLRequest) -> String {
        if let method = request.httpMethod, let url = request.url {
            return "\(method) \(url)"
        }
        return "<Invalid Method/URL>"
    }

    private func prettyHeaders(headers: [String: String]?) -> String? {
        guard let headers = headers, headers.isEmpty == false else {
            return nil
        }
        let allHeaders: [String] = headers.map { "  \($0.key): \($0.value)" }
        let joined: String = allHeaders.joined(separator: "\n")
        return "Headers: {\n\(joined)\n}"
    }

    private func makeStatusDescription(code: Int?) -> String {
        guard let code = code,
            code > 0 else {
                return "<No Response> 🚫"
        }
        let statusSymbol: String

        switch code {
        case 200..<300:
            statusSymbol = "✅"
        case 300..<400:
            statusSymbol = "↪️"
        case 401, 403:
            statusSymbol = "⛔️"
        case 404:
            statusSymbol = "🔎"
        case 400..<500:
            statusSymbol = "❌"
        case 500..<Int.max:
            statusSymbol = "💥"
        default:
            statusSymbol = "❓"
        }

        return "\(code) \(statusSymbol)"
    }

}
