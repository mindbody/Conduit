//
//  OAuth2TokenGrantStrategy.swift
//  Conduit
//
//  Created by John Hammerlund on 7/11/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Defines a type that attempts a token grant from an OAuth2 server application
public protocol OAuth2TokenGrantStrategy {

    /// Attempts to issue a token with the given grant type
    ///
    /// - Parameters:
    ///   - completion: A closure that executes on token grant success/failure
    func issueToken(completion: @escaping Result<BearerToken>.Block)

    /// Attempts to issue a token with the given grant type
    ///
    /// - Returns: Access token
    /// - Throws: Error if token grant failed
    func issueToken() throws -> BearerToken

}

extension OAuth2TokenGrantStrategy {

    func buildStandardTokenGrantRequest(clientConfiguration: OAuth2ClientConfiguration,
                                        grantType: String,
                                        additionalGrantParameters: [String:Any],
                                        requestSerializer: RequestSerializer = JSONRequestSerializer()) throws -> URLRequest {
        let basicToken = BasicToken(username: clientConfiguration.clientIdentifier, password: clientConfiguration.clientSecret)

        let requestBuilder = HTTPRequestBuilder(url: clientConfiguration.environment.tokenGrantURL)
        var parameters: [String:Any] = [
            "grant_type": grantType
        ]

        if let scope = clientConfiguration.environment.scope {
            parameters["scope"] = scope
        }

        for additionalParameter in additionalGrantParameters {
            parameters[additionalParameter.key] = additionalParameter.value
        }

        requestBuilder.bodyParameters = parameters
        requestBuilder.method = .POST
        requestBuilder.serializer = requestSerializer
        do {
            var request = try requestBuilder.build()
            request.setValue(basicToken.authorizationHeaderValue, forHTTPHeaderField: "Authorization")
            return request
        }
        catch let error {
            logger.error("Encountered an error building the token request. Error: \(error)")
            throw OAuth2Error.internalFailure
        }
    }
}
