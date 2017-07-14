//
//  OAuth2Middleware.swift
//  Conduit
//
//  Created by John Hammerlund on 7/29/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// A middleware component for use within a URLSessionClient pipeline. Specifically,
/// this component will pause the pipeline once the token is no longer valid, refresh the token when needed,
/// and apply authorization headers to piped requests.
public struct OAuth2RequestPipelineMiddleware: RequestPipelineMiddleware {

    public var pipelineBehaviorOptions: RequestPipelineBehaviorOptions {
        return token?.isValid == true ? .none : .awaitsOutgoingCompletion
    }
    let clientConfiguration: OAuth2ClientConfiguration
    let authorization: OAuth2Authorization
    let tokenStorage: OAuth2TokenStore

    var token: OAuth2Token? {
        return tokenStorage.tokenFor(client: clientConfiguration, authorization: authorization)
    }

    /// Creates a new OAuth2RequestPipelineMiddleware
    /// - Parameters:
    ///   - clientConfiguration: The configuration of the OAuth2 client
    ///   - authorization: The needed authorization type and level needed to decorate the request
    ///   - tokenStorage: The storage mechanism used to retrieve and update tokens
    public init(clientConfiguration: OAuth2ClientConfiguration,
                authorization: OAuth2Authorization,
                tokenStorage: OAuth2TokenStore) {
        self.clientConfiguration = clientConfiguration
        self.authorization = authorization
        self.tokenStorage = tokenStorage
    }

    public func prepareForTransport(request: URLRequest, completion: @escaping (Result<URLRequest>) -> Void) {
        let url = request.url?.absoluteString ?? "(Unknown URL)"
        let method = request.httpMethod ?? "(Unknown Method)"
        logger.verbose("Applying auth header to outgoing request: \(method) \(url)")
        if let token = self.token, token.isValid {
            logger.verbose("Token is valid, proceeding to middleware completion")
            makeRequestByApplyingAuthorizationHeader(to: request, with: token, completion: completion)
        }
        else if let token = self.token as? BearerOAuth2Token,
            token.refreshToken != nil {
            logger.info("Token is expired, proceeding to refresh token")
            refresh(token: token) { result in
                switch result {
                case .error(let error):
                    logger.warn("There was an error refreshing the token")
                    if case OAuth2Error.clientFailure(_) = error {
                        self.tokenStorage.store(token: nil, for: self.clientConfiguration, with: self.authorization)
                    }
                    completion(.error(error))
                case .value(let newToken):
                    logger.info("Successfully refreshed token")
                    logger.debug("New token issued: \(newToken)")
                    self.tokenStorage.store(token: newToken, for: self.clientConfiguration, with: self.authorization)
                    self.makeRequestByApplyingAuthorizationHeader(to: request, with: newToken, completion: completion)
                }
            }
        }
        else if authorization.level == .client {
            logger.verbose("No bearer token found, but client authorization is requested.")
            if authorization.type == .bearer {
                // Issue new token with client username/password and then apply bearer header
                issueTokenForClientUser { result in
                    switch result {
                    case .error(let error):
                        logger.warn("There was an error issuing the new client token")
                        self.tokenStorage.store(token: nil, for: self.clientConfiguration, with: self.authorization)
                        completion(.error(error))
                    case .value(let newToken):
                        logger.info("Successfully issued token")
                        logger.debug("New token issued: \(newToken)")
                        self.tokenStorage.store(token: newToken,
                                                for: self.clientConfiguration,
                                                with: self.authorization)
                        self.makeRequestByApplyingAuthorizationHeader(to: request,
                                                                      with: newToken,
                                                                      completion: completion)
                    }
                    Auth.Migrator.notifyTokenPostFetchHooksWith(client: self.clientConfiguration,
                                                                authorizationLevel: self.authorization.level,
                                                                result: result)
                }
            }
            else {
                // Apply basic header
                logger.verbose("Client doesn't require a bearer token. Proceeding with a basic token...")
                let basicToken = BasicOAuth2Token(username: clientConfiguration.clientIdentifier,
                                                  password: clientConfiguration.clientSecret)
                makeRequestByApplyingAuthorizationHeader(to: request,
                                                         with: basicToken,
                                                         completion: completion)
            }
        }
        else {
            logger.warn("Invalid or empty token supplied for user authorization")
            completion(.error(OAuth2Error.clientFailure(nil, nil)))
        }
    }

    private func issueTokenForClientUser(_ completion: @escaping Result<BearerOAuth2Token>.Block) {
        // If guest user credentials exist, we attempt a password grant
        // Otherwise, we attempt a client_credentials grant
        logger.verbose("About to issue a new client bearer token...")
        let authenticationStrategy: OAuth2TokenGrantStrategy

        if let username = clientConfiguration.guestUsername,
            let password = clientConfiguration.guestPassword {
            logger.verbose("Guest user credentials exist. Attempting password grant...")
            authenticationStrategy = OAuth2PasswordTokenGrantStrategy(username: username,
                                                                      password: password,
                                                                      clientConfiguration: clientConfiguration)
        }
        else {
            logger.verbose("Guest user credentials do not exist. Attempting client_credentials grant...")
            authenticationStrategy = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: clientConfiguration)
        }
        Auth.Migrator.notifyTokenPreFetchHooksWith(client: clientConfiguration,
                                                   authorizationLevel: authorization.level)

        authenticationStrategy.issueToken(completion)
    }

    private func makeRequestByApplyingAuthorizationHeader(to request: URLRequest,
                                                          with token: OAuth2Token,
                                                          completion: Result<URLRequest>.Block) {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            logger.error("There was an issue building an authorized request within the OAuth2RequestPipelineMiddleware")
            completion(.error(OAuth2Error.internalFailure))
            return
        }

        mutableRequest.setValue(token.authorizationHeaderValue, forHTTPHeaderField: "Authorization")
        guard let request = mutableRequest.copy() as? URLRequest else {
            logger.error("There was an issue building an authorized request within the OAuth2RequestPipelineMiddleware")
            completion(.error(OAuth2Error.internalFailure))
            return
        }
        completion(.value(request))
    }

    private func buildTokenRefreshRequestFor(token: BearerOAuth2Token, completion: Result<URLRequest>.Block) {
        guard let refreshToken = token.refreshToken else {
            logger.warn([
                "A request required Bearer authorization, but the expired token",
                "does not have an available refresh token"
            ].joined(separator: " "))
            completion(.error(OAuth2Error.internalFailure))
            return
        }

        let basicToken = BasicOAuth2Token(username: clientConfiguration.clientIdentifier,
                                          password: clientConfiguration.clientSecret)

        let requestBuilder = HTTPRequestBuilder(url: clientConfiguration.environment.tokenGrantURL)
        requestBuilder.bodyParameters = ["grant_type": "refresh_token",
                                         "refresh_token": refreshToken,
                                         "scope": clientConfiguration.environment.scope]
        requestBuilder.method = .POST
        requestBuilder.serializer = FormEncodedRequestSerializer()

        do {
            let mutableRequest = try requestBuilder.build()
            makeRequestByApplyingAuthorizationHeader(to: mutableRequest, with: basicToken, completion: completion)
        }
        catch let error {
            logger.error("There was an issue building an authorized request within the OAuth2RequestPipelineMiddleware")
            logger.debug("RequestBuilder Error: \(error)")
            completion(.error(OAuth2Error.internalFailure))
        }
    }

    private func refresh(token: BearerOAuth2Token, completion: @escaping Result<BearerOAuth2Token>.Block) {
        Auth.Migrator.notifyTokenPreFetchHooksWith(client: clientConfiguration,
                                                   authorizationLevel: authorization.level)

        buildTokenRefreshRequestFor(token: token) { result in
            var request: URLRequest
            switch result {
            case .error(let error):
                completion(.error(error))
                return
            case .value(let req):
                request = req
            }

            OAuth2TokenGrantManager.issueTokenWith(authorizedRequest: request) { result in
                completion(result)
                Auth.Migrator.notifyTokenPostFetchHooksWith(client: self.clientConfiguration,
                                                            authorizationLevel: self.authorization.level,
                                                            result: result)
            }
        }
    }

}
