//
//  OAuth2RefreshTokenGrantStrategy.swift
//  Conduit
//
//  Created by John Hammerlund on 6/6/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

/// Attempts a token grant via the "refresh_token" grant type
public struct OAuth2RefreshTokenGrantStrategy: OAuth2TokenGrantStrategy {

    private let refreshToken: String
    private let clientConfiguration: OAuth2ClientConfiguration

    /// For server applications with complex realms, additional factors or user information
    /// may be necessary for user authentication
    public var tokenGrantRequestAdditionalBodyParameters: [String: Any] = [:]

    /// The serializer used for token grant requests. Defaults to a FormEncodedRequestSerializer.
    public var requestSerializer: RequestSerializer = FormEncodedRequestSerializer()

    /// The deserializer used for token grant responses. Defaults to a JSONResponseDeserializer.
    public var responseDeserializer: ResponseDeserializer = JSONResponseDeserializer()

    /// Creates a new OAuth2RefreshTokenGrantStrategy
    /// - Parameters:
    ///   - refreshToken: The refresh_token issued in a previous grant
    ///   - clientConfiguration: The configuration of the OAuth2 client
    public init(refreshToken: String, clientConfiguration: OAuth2ClientConfiguration) {
        self.refreshToken = refreshToken
        self.clientConfiguration = clientConfiguration
    }

    func buildTokenGrantRequest() throws -> URLRequest {
        var factors: [String: Any] = [
            "refresh_token": refreshToken
        ]
        for additionalParameter in tokenGrantRequestAdditionalBodyParameters {
            factors[additionalParameter.key] = additionalParameter.value
        }
        let request = try buildStandardTokenGrantRequest(clientConfiguration: clientConfiguration,
                                                         grantType: "refresh_token",
                                                         additionalGrantParameters: factors,
                                                         requestSerializer: requestSerializer)
        return request
    }

    public func issueToken(completion: @escaping Result<BearerToken>.Block) {
        logger.verbose("Attempting to issue a new token via refresh_token...")
        do {
            let request = try buildTokenGrantRequest()
            OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request, responseDeserializer: responseDeserializer, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }

    public func issueToken() throws -> BearerToken {
        logger.verbose("Attempting to issue a new token via refresh_token...")
        let request = try buildTokenGrantRequest()
        return try OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request)
    }

}

/// Builds an OAuth2RefreshTokenGrantStrategy to handle a token refresh
public struct OAuth2TokenRefreshGrantStrategyFactory: OAuth2RefreshStrategyFactory {

    public func make(refreshToken: String, clientConfiguration: OAuth2ClientConfiguration) -> OAuth2TokenGrantStrategy {
        return OAuth2RefreshTokenGrantStrategy(refreshToken: refreshToken, clientConfiguration: clientConfiguration)
    }

}
