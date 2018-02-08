//
//  ConduitError.swift
//  Conduit
//
//  Created by John Hammerlund on 8/3/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An error that prevented Conduit from fulfilling a given task.
///
/// - internalFailure: An unexpected error occurred within the framework.
/// - noResponse: A network request expected to return a response, returned no reponse.
///               Usually, the server application failed to respond within the timeout.
/// - requestFailure: The server response indicates a bad request.
/// - serializationError: Serialization error.
/// - deserializationError: Deserialization error.
public enum ConduitError: Error {
    case internalFailure(message: String)
    case noResponse(request: URLRequest?)
    case requestFailure(taskResponse: SessionTaskResponse)
    case serializationError(message: String)
    case deserializationError(data: Data?, type: Any.Type)
}

// MARK: LocalizedError

extension ConduitError: LocalizedError {
    public var errorDescription: String? {
        switch self {

        case .internalFailure(let message):
            return "Conduit Internal Error: \(message)"

        case .noResponse(let request):
            let url = request?.url?.absoluteString ?? ""
            return "Received No Response: \(url)"

        case .requestFailure(let taskResponse):
            let url = taskResponse.request?.url?.absoluteString ?? ""
            let statusCode = taskResponse.response?.statusCode ?? 0
            return """
            Request failed:
            - Url: \(url)
            - Status Code: \(statusCode)
            """

        case .serializationError(let message):
            return "Failed to serialize object: \(message)"

        case let .deserializationError(data, type):
            let message = "Failed to deserialize data into an entity of type \(type)"
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                return """
                \(message):
                \(dataString)
                """
            }
            return message
        }
    }
}
