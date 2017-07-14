//
//  OAuth2ExtensionTokenGrantStrategy.swift
//  Conduit
//
//  Created by John Hammerlund on 7/6/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Attempts a token grant via  a custom extension grant as defined in
/// [RFC 6749 Section 4.5](https://tools.ietf.org/html/rfc6749#section-4.5)
public struct OAuth2ExtensionTokenGrantStrategy: OAuth2TokenGrantStrategy {

    private let grantType: String
    private let clientConfiguration: OAuth2ClientConfiguration

    /// For server applications with complex realms, additional factors or user information
    /// may be necessary for user authentication
    public var tokenGrantRequestAdditionalBodyParameters: [String:Any] = [:]

    /// The serializer used for token grant requests. Defaults to a FormEncodedRequestSerializer.
    public var requestSerializer: RequestSerializer = FormEncodedRequestSerializer()

    /// The deserializer used for token grant responses. Defaults to a JSONResponseDeserializer.
    public var responseDeserializer: ResponseDeserializer = JSONResponseDeserializer()

    /// Creates a new OAuth2ExtensionTokenGrantStrategy
    /// - Parameters:
    ///   - grantType: The custom grant_type
    ///   - clientConfiguration: The configuration of the OAuth2 client
    public init(grantType: String, clientConfiguration: OAuth2ClientConfiguration) {
        self.grantType = grantType
        self.clientConfiguration = clientConfiguration
    }

    func buildTokenGrantRequest() throws -> URLRequest {
        let request = try buildStandardTokenGrantRequest(clientConfiguration: clientConfiguration,
                                                         grantType: grantType,
                                                         additionalGrantParameters: tokenGrantRequestAdditionalBodyParameters,
                                                         requestSerializer: requestSerializer)
        return request
    }

    public func issueToken(_ completion: @escaping Result<BearerOAuth2Token>.Block) {
        logger.verbose("Attempting to issue a new token via extension grant...")
        do {
            let request = try buildTokenGrantRequest()
            OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request, responseDeserializer: responseDeserializer, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }

}
