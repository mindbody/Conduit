//
//  ConduitError.swift
//  Conduit
//
//  Created by John Hammerlund on 8/3/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An error that prevented Conduit from fulfilling a given task.
public enum ConduitError: Error {

    /// An unexpected error occurred within the framework.
    case internalFailure(message: String)

    /// A network request expected to return a response, returned no reponse.
    /// Usually, the server application failed to respond within the timeout.
    case noResponse(request: URLRequest?)

    /// The server response indicates a bad request.
    case requestFailure(taskResponse: SessionTaskResponse)

    /// Serialization error
    case serializationError(message: String)

    /// Deserialization error
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
