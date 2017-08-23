//
//  OAuth2PasswordTokenGrantStrategy.swift
//  Conduit
//
//  Created by John Hammerlund on 7/14/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Attempts a token grant via the "password" implicit grant type
public struct OAuth2PasswordTokenGrantStrategy: OAuth2TokenGrantStrategy {

    private let username: String
    private let password: String
    private let clientConfiguration: OAuth2ClientConfiguration

    /// For server applications with complex realms, additional factors or user information
    /// may be necessary for user authentication
    public var tokenGrantRequestAdditionalBodyParameters: [String:Any] = [:]

    /// The serializer used for token grant requests. Defaults to a FormEncodedRequestSerializer.
    public var requestSerializer: RequestSerializer = FormEncodedRequestSerializer()

    /// The deserializer used for token grant responses. Defaults to a JSONResponseDeserializer.
    public var responseDeserializer: ResponseDeserializer = JSONResponseDeserializer()

    /// Creates a new OAuth2PasswordTokenGrantStrategy
    /// - Parameters:
    ///   - username: The resource owner's username
    ///   - password: The resource owner's password
    ///   - clientConfiguration: The configuration of the OAuth2 client
    public init(username: String, password: String, clientConfiguration: OAuth2ClientConfiguration) {
        self.username = username
        self.password = password
        self.clientConfiguration = clientConfiguration
    }

    func buildTokenGrantRequest() throws -> URLRequest {
        var factors: [String:Any] = [
            "username": username,
            "password": password
        ]
        for additionalParameter in tokenGrantRequestAdditionalBodyParameters {
            factors[additionalParameter.key] = additionalParameter.value
        }
        let request = try buildStandardTokenGrantRequest(clientConfiguration: clientConfiguration,
                                                         grantType: "password",
                                                         additionalGrantParameters: factors,
                                                         requestSerializer: requestSerializer)
        return request
    }

    public func issueToken(_ completion: @escaping Result<BearerToken>.Block) {
        logger.verbose("Attempting to issue a new token via username and password...")
        do {
            let request = try buildTokenGrantRequest()
            OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request, responseDeserializer: responseDeserializer, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }

}
