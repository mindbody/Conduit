//
//  OAuth2ClientCredentialsTokenGrantStrategyy.swift
//  Conduit
//
//  Created by John Hammerlund on 2/17/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Attempts a token grant via the "client_credentials" implicit grant type
public struct OAuth2ClientCredentialsTokenGrantStrategy: OAuth2TokenGrantStrategy {

    let clientConfiguration: OAuth2ClientConfiguration

    /// For server applications with complex realms, additional factors or user information
    /// may be necessary for user authentication
    public var tokenGrantRequestAdditionalBodyParameters: [String : Any] = [:]

    /// The serializer used for token grant requests. Defaults to a FormEncodedRequestSerializer.
    public var requestSerializer: RequestSerializer = FormEncodedRequestSerializer()

    /// The deserializer used for token grant responses. Defaults to a JSONResponseDeserializer.
    public var responseDeserializer: ResponseDeserializer = JSONResponseDeserializer()

    public init(clientConfiguration: OAuth2ClientConfiguration) {
        self.clientConfiguration = clientConfiguration
    }

    func buildTokenGrantRequest() throws -> URLRequest {
        let additionalParameters = tokenGrantRequestAdditionalBodyParameters
        let request = try buildStandardTokenGrantRequest(clientConfiguration: clientConfiguration,
                                                         grantType: "client_credentials",
                                                         additionalGrantParameters: additionalParameters,
                                                         requestSerializer: requestSerializer)
        return request
    }

    public func issueToken(_ completion: @escaping Result<BearerOAuth2Token>.Block) {
        logger.verbose("Attempting to issue a new token with client credentials...")
        do {
            let request = try buildTokenGrantRequest()
            OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }

}
