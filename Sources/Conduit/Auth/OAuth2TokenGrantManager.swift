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

        sessionClient.begin(request: authorizedRequest) { data, response, error in
            if let error = self.errorFrom(data: data, response: response, error: error) {
                completion(.error(error))
                return
            }
            let authTokenJSON: [String: Any]
            do {
                guard let deserializedResponse = try responseDeserializer.deserialize(response: response, data: data) as? [String: Any] else {
                        completion(.error(OAuth2Error.noResponse))
                        return
                }
                authTokenJSON = deserializedResponse
            }
            catch _ {
                completion(.error(OAuth2Error.internalFailure))
                return
            }
            guard let newToken = BearerToken.mapFrom(JSON: authTokenJSON) else {
                completion(.error(OAuth2Error.internalFailure))
                return
            }
            completion(.value(newToken))
        }
    }

    static func issueTokenWith(authorizedRequest: URLRequest, responseDeserializer: ResponseDeserializer = JSONResponseDeserializer()) throws -> BearerToken {
        let sessionClient = OAuth2URLSessionClientFactory.makeClient()

        let result = try sessionClient.begin(request: authorizedRequest)
        if let error = errorFrom(data: result.data, response: result.response) {
            throw error
        }
        guard let authTokenJSON = try responseDeserializer.deserialize(response: result.response, data: result.data) as? [String: Any] else {
            throw OAuth2Error.noResponse
        }
        guard let newToken = BearerToken.mapFrom(JSON: authTokenJSON) else {
            throw OAuth2Error.internalFailure
        }
        return newToken
    }

    static func errorFrom(data: Data?, response: HTTPURLResponse?, error: Error? = nil) -> Error? {
        if (error as? NSError)?.domain == NSURLErrorDomain {
            return OAuth2Error.networkFailure
        }

        guard let response = response else {
            return OAuth2Error.noResponse
        }

        switch response.statusCode {
        case 401:
            return OAuth2Error.clientFailure(data, response)
        case 400..<500:
            return OAuth2Error.clientFailure(data, response)
        case 500...:
            return OAuth2Error.serverFailure(data, response)
        default:
            return nil
        }
    }
}
