//
//  ProtectedResourceService.swift
//  ConduitExample
//
//  Created by John Hammerlund on 6/23/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
import Conduit

struct ProtectedResourceService {

    private let apiBaseURL = URL(string: "http://localhost:5000")!

    func fetchThing(completion: @escaping Result<ProtectedThing>.Block) {
        let userBearerAuthorization = OAuth2Authorization(type: .bearer, level: .user)
        let clientConfiguration = AuthManager.shared.localClientConfiguration

        var urlComponents = URLComponents(url: apiBaseURL, resolvingAgainstBaseURL: false)
        urlComponents?.path = "/answers/life"
        guard let url = urlComponents?.url else {
            completion(.error(RequestSerializerError.invalidURL))
            return
        }

        let builder = HTTPRequestBuilder(url: url)
        builder.method = .GET
        /// We typically use a JSON serializer, but serializers exist for most other common transport operations
        /// and content types (XML/SOAP, multipart form-data, www-form-encoded)
        builder.serializer = JSONRequestSerializer()
        /// Here, we can also configure special formatting options and declare query string parameters
        /// or POST/PUT/PATCH input fields
        //        builder.queryStringFormattingOptions.dictionaryFormat = .subscripted
        //        builder.queryStringFormattingOptions.plusSymbolEncodingRule = .replacedWithEncodedPlus
        //        builder.queryStringFormattingOptions.arrayFormat = .commaSeparated
        //        builder.queryStringParameters = ["key" : ["value 1", "value 2"]]

        let request: URLRequest
        do {
            request = try builder.build()
        }
        catch {
            completion(.error(error))
            return
        }
        var sessionClient = URLSessionClientManager.localAPISessionClient

        /// OAuth2 token management, including refreshing where applicable, is completely handled by a middleware component.
        /// When a new token needs to be fetched for any means (and Conduit has the needed credentials or refresh token),
        /// the network pipeline will freeze, all outgoing requests will finish, a new token will be fetched, and
        /// request processing will resume.
        let authMiddleware = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration,
                                                             authorization: userBearerAuthorization,
                                                             tokenStorage: AuthManager.shared.localTokenStore)
        sessionClient.middleware.append(authMiddleware)

        sessionClient.begin(request: request) { (data, response, error) in
            let responseDeserializer = JSONResponseDeserializer()
            let dto: ProtectedThing
            do {
                guard let json = try responseDeserializer.deserialize(response: response, data: data) as? [String : Any] else {
                    throw ResponseDeserializerError.deserializationFailure
                }
                dto = try ProtectedThing(json: json)
            }
            catch {
                completion(.error(error))
                return
            }
            completion(.value(dto))
        }
    }

}
