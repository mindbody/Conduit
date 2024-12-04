//
//  OAuth2ExtensionTokenGrantsStrategy.swift
//  Conduit
//
//  Created by Anshul Jain on 03/12/24.
//

import Foundation

public struct OAuth2DelegationTokenGrantStrategy: OAuth2TokenGrantStrategy {

    private let clientConfiguration: OAuth2ClientConfiguration

    /// For server applications with complex realms, additional factors or user information
    /// may be necessary for user authentication
    public var tokenGrantRequestAdditionalBodyParameters: [String: Any] = [:]

    /// The serializer used for token grant requests. Defaults to a FormEncodedRequestSerializer.
    public var requestSerializer: RequestSerializer = FormEncodedRequestSerializer()

    /// The deserializer used for token grant responses. Defaults to a JSONResponseDeserializer.
    public var responseDeserializer: ResponseDeserializer = JSONResponseDeserializer()

    /// Creates a new OAuth2DelegationTokenGrantStrategy
    /// - Parameters:
    ///   - clientConfiguration: The configuration of the OAuth2 client
    public init(clientConfiguration: OAuth2ClientConfiguration) {
        self.clientConfiguration = clientConfiguration
    }

    func buildTokenGrantRequest() throws -> URLRequest {
        let request = try buildStandardTokenGrantRequest(clientConfiguration: clientConfiguration,
                                                         grantType: "delegation",
                                                         additionalGrantParameters: tokenGrantRequestAdditionalBodyParameters,
                                                         requestSerializer: requestSerializer)
        return request
    }

    public func issueToken(completion: @escaping Result<BearerToken>.Block) {
        logger.verbose("Attempting to issue a new token via extension grant...")
        do {
            let request = try buildTokenGrantRequest()
            OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request, responseDeserializer: responseDeserializer, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }

    public func issueToken() throws -> BearerToken {
        logger.verbose("Attempting to issue a new token via extension grant...")
        let request = try buildTokenGrantRequest()
        return try OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request)
    }

}
