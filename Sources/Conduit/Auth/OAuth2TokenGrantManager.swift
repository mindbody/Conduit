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
                               completion: @escaping Result<BearerOAuth2Token>.Block) {
        let sessionClient = OAuth2URLSessionClientFactory.makeClient()

        sessionClient.begin(request: authorizedRequest) { (data, response, error) in
            let authTokenJSON: [String:Any]
            if let error = self.errorFrom(data: data, response: response) {
                completion(.error(error))
                return
            }
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
            guard let newToken = BearerOAuth2Token.mapFrom(JSON: authTokenJSON) else {
                completion(.error(OAuth2Error.internalFailure))
                return
            }
            completion(.value(newToken))
        }
    }

    static func errorFrom(data: Data?, response: HTTPURLResponse?) -> Error? {
        guard let response = response else {
            return OAuth2Error.noResponse
        }

        switch response.statusCode {
        case 401:
            return OAuth2Error.clientFailure(data, response)
        case 400..<500:
            return OAuth2Error.clientFailure(data, response)
        case 500..<Int.max:
            return OAuth2Error.serverFailure(data, response)
        default:
            return nil
        }
    }
}
