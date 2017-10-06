//
//  OAuth2AuthorizationCodeTokenGrantStrategy.swift
//  Conduit
//
//  Created by John Hammerlund on 6/28/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Attempts a token grant via the "authorization_code" grant type
public struct OAuth2AuthorizationCodeTokenGrantStrategy: OAuth2TokenGrantStrategy {

    private let code: String
    private let redirectURI: String
    private let clientConfiguration: OAuth2ClientConfiguration

    /// For server applications with complex realms, additional factors or user information
    /// may be necessary for user authentication
    public var tokenGrantRequestAdditionalBodyParameters: [String: Any] = [:]

    /// The serializer used for token grant requests. Defaults to a FormEncodedRequestSerializer.
    public var requestSerializer: RequestSerializer = FormEncodedRequestSerializer()

    /// The deserializer used for token grant responses. Defaults to a JSONResponseDeserializer.
    public var responseDeserializer: ResponseDeserializer = JSONResponseDeserializer()

    /// Creates a new OAuth2AuthorizationCodeTokenGrantStrategy
    /// - Parameters:
    ///   - code: The authorization_code returned from a successful authorization request
    ///   - redirectURI: The original authorization request's redirect_uri
    ///   - clientConfiguration: The configuration of the OAuth2 client
    public init(code: String, redirectURI: String, clientConfiguration: OAuth2ClientConfiguration) {
        self.code = code
        self.redirectURI = redirectURI
        self.clientConfiguration = clientConfiguration
    }

    func buildTokenGrantRequest() throws -> URLRequest {
        var factors: [String: Any] = [
            "code": code,
            "redirect_uri": redirectURI
        ]
        for additionalParameter in tokenGrantRequestAdditionalBodyParameters {
            factors[additionalParameter.key] = additionalParameter.value
        }

        // Specifically for this grant, scope is already determined by the authorization workflow itself (often configured by the user)
        var configuration = clientConfiguration
        configuration.environment.scope = nil

        let request = try buildStandardTokenGrantRequest(clientConfiguration: configuration,
                                                         grantType: "authorization_code",
                                                         additionalGrantParameters: factors,
                                                         requestSerializer: requestSerializer)
        return request
    }

    public func issueToken(completion: @escaping Result<BearerToken>.Block) {
        logger.verbose("Attempting to issue a new token via authorization code...")
        do {
            let request = try buildTokenGrantRequest()
            OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request, responseDeserializer: responseDeserializer, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }

    public func issueToken() throws -> BearerToken {
        logger.verbose("Attempting to issue a new token via authorization code...")
        let request = try buildTokenGrantRequest()
        return try OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request, responseDeserializer: responseDeserializer)
    }

}
