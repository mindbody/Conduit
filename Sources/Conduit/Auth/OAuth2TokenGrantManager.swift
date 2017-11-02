//
//  OAuth2TokenGrantManager.swift
//  Conduit
//
//  Created by John Hammerlund on 8/2/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

struct OAuth2TokenGrantManager {

    static func issueTokenWith(authorizedRequest: URLRequest, responseDeserializer: ResponseDeserializer = JSONResponseDeserializer(),
                               completion: @escaping Result<BearerToken>.Block) {
        let sessionClient = OAuth2URLSessionClientFactory.makeClient()

        sessionClient.begin(request: authorizedRequest) { taskResponse in
            if let error = self.errorFrom(taskResponse: taskResponse) {
                completion(.error(error))
                return
            }
            let authTokenJSON: [String: Any]
            do {
                guard let deserializedResponse = try responseDeserializer.deserialize(response: taskResponse.response, data: taskResponse.data)
                    as? [String: Any] else {
                        completion(.error(ConduitError.noResponse(request: authorizedRequest)))
                        return
                }
                authTokenJSON = deserializedResponse
            }
            catch _ {
                completion(.error(ConduitError.deserializationError(data: taskResponse.data, type: BearerToken.self)))
                return
            }
            guard let newToken = BearerToken.mapFrom(JSON: authTokenJSON) else {
                completion(.error(ConduitError.deserializationError(data: taskResponse.data, type: BearerToken.self)))
                return
            }
            completion(.value(newToken))
        }
    }

    static func issueTokenWith(authorizedRequest: URLRequest, responseDeserializer: ResponseDeserializer = JSONResponseDeserializer()) throws -> BearerToken {
        let sessionClient = OAuth2URLSessionClientFactory.makeClient()

        let taskResponse = try sessionClient.begin(request: authorizedRequest)
        if let error = errorFrom(taskResponse: taskResponse) {
            throw error
        }
        guard let authTokenJSON = try responseDeserializer.deserialize(response: taskResponse.response, data: taskResponse.data) as? [String: Any] else {
            throw ConduitError.noResponse(request: authorizedRequest)
        }
        guard let newToken = BearerToken.mapFrom(JSON: authTokenJSON) else {
            throw ConduitError.deserializationError(data: taskResponse.data, type: BearerToken.self)
        }
        return newToken
    }

    static func errorFrom(taskResponse: SessionTaskResponse) -> ConduitError? {
        guard let response = taskResponse.response else {
            if let request = taskResponse.request {
                return ConduitError.noResponse(request: request)
            }
            else {
                return ConduitError.internalFailure(message: "No request found")
            }
        }

        if response.statusCode >= 400 {
            return ConduitError.requestFailure(taskResponse: taskResponse)
        }
        return nil
    }
}
