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
    /// Provides a grant strategy to handle a token refresh. Defaults to OAuth2TokenRefreshGrantStrategyFactory.
    public var refreshStrategyFactory: OAuth2RefreshStrategyFactory? = OAuth2TokenRefreshGrantStrategyFactory()
    /// The maximum amount of time that multi-session locks should be issued when performing token refreshes.
    /// Short-lived processes, such as app extensions, should typically set a lower relinquish interval to defend
    /// against lengthy session locks when terminating mid-flight. This will allow the host process to quickly pick
    /// up where the other process left off, if it needs to. Defaults to 30 seconds.
    public var tokenRefreshLockRelinquishInterval: TimeInterval = 30
    /// Kill switch for atomic in-process refresh serialization; static because instances are per-client value copies. Defaults to true.
    public static var refreshClaimCoordinationEnabled = true
    let clientConfiguration: OAuth2ClientConfiguration
    let authorization: OAuth2Authorization
    let tokenStorage: OAuth2TokenStore

    var token: BearerToken? {
        guard let token: BearerToken = tokenStorage.tokenFor(client: clientConfiguration, authorization: authorization) else {
            return nil
        }
        return token
    }

    /// One refresh claim per client + authorization, keyed by the store's canonical token identifier.
    private var refreshClaimKey: String {
        tokenStorage.tokenIdentifierFor(clientConfiguration: clientConfiguration, authorization: authorization) + ".refresh-claim"
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

    // Over the body-length limit only while the pre-coordination path stays inline; remove with it.
    // swiftlint:disable:next function_body_length
    public func prepareForTransport(request: URLRequest, completion: @escaping (Result<URLRequest>) -> Void) {
        let url = request.url?.absoluteString ?? "(Unknown URL)"
        let method = request.httpMethod ?? "(Unknown Method)"
        logger.verbose("Applying auth header to outgoing request: \(method) \(url)")
        if let token = token, token.isValid {
            logger.verbose("Token is valid, proceeding to middleware completion")
            makeRequestByApplyingAuthorizationHeader(to: request, with: token, completion: completion)
        }
        else if let token = token,
            token.refreshToken != nil,
            refreshStrategyFactory != nil {
            if OAuth2RequestPipelineMiddleware.refreshClaimCoordinationEnabled {
                refreshTokenAndResume(request: request, completion: completion)
                return
            }
            if tokenStorage.isRefreshTokenLockedFor(client: clientConfiguration, authorization: authorization),
                let tokenLockExpiration = tokenStorage.refreshTokenLockExpirationFor(client: clientConfiguration, authorization: authorization) {
                logger.info("Token refresh is active in an alternate session; retrying once lock is relinquished")
                let timeout = max(0, tokenLockExpiration.timeIntervalSinceNow)
                OAuth2TokenRefreshCoordinator.shared.waitForRefresh(timeout: timeout) {
                    /// If we hit the edge case where an unrelated session triggers OAuth2TokenRefreshCoordinator.endTokenRefresh(),
                    /// then we'll recursively fall back into this branch
                    self.prepareForTransport(request: request, completion: completion)
                }
                return
            }
            tokenStorage.lockRefreshToken(timeout: tokenRefreshLockRelinquishInterval, client: clientConfiguration, authorization: authorization)
            logger.info("Token is expired, proceeding to refresh token")
            OAuth2TokenRefreshCoordinator.shared.beginTokenRefresh()

            refresh(token: token) { result in
                switch result {
                case .error(let error):
                    logger.warn("There was an error refreshing the token")
                    if case OAuth2Error.clientFailure = error {
                        self.tokenStorage.removeTokenFor(client: self.clientConfiguration, authorization: self.authorization)
                    }
                    tokenStorage.unlockRefreshTokenFor(client: clientConfiguration, authorization: authorization)
                    completion(.error(error))
                case .value(let newToken):
                    logger.info("Successfully refreshed token")
                    logger.debug("New token issued: \(newToken)")
                    self.tokenStorage.store(token: newToken, for: self.clientConfiguration, with: self.authorization)
                    tokenStorage.unlockRefreshTokenFor(client: clientConfiguration, authorization: authorization)

                    /// Resume original request using freshly obtained bearer token
                    self.makeRequestByApplyingAuthorizationHeader(to: request, with: newToken, completion: completion)
                }
                OAuth2TokenRefreshCoordinator.shared.endTokenRefresh()
            }
        }
        else if authorization.level == .client {
            prepareForTransportWithClientAuthorization(request: request, completion: completion)
        }
        else {
            logger.warn("Invalid or empty token supplied for user authorization")
            completion(.error(OAuth2Error.clientFailure(nil, nil)))
        }
    }

    /// Refreshes the expired token and resumes the request; cross-process coordination via the storage lock, in-process via the claim registry.
    private func refreshTokenAndResume(request: URLRequest, completion: @escaping (Result<URLRequest>) -> Void) {
        if tokenStorage.isRefreshTokenLockedFor(client: clientConfiguration, authorization: authorization),
            let tokenLockExpiration = tokenStorage.refreshTokenLockExpirationFor(client: clientConfiguration, authorization: authorization) {
            logger.info("Token refresh is active in an alternate session; retrying once lock is relinquished")
            // Cap the wait: re-entry re-checks all state, so a missed unbuffered wake costs one short poll, not the lock lifetime.
            let timeout = min(0.5, max(0, tokenLockExpiration.timeIntervalSinceNow))
            waitForRefreshThenResumeOnce(timeout: timeout, request: request, completion: completion)
            return
        }
        let claimKey = refreshClaimKey
        guard let claimGeneration = OAuth2RefreshClaimRegistry.shared.tryClaim(key: claimKey,
                                                                               staleAfter: tokenRefreshLockRelinquishInterval) else {
            // A refresh is already in flight in this process; a second grant would double-spend the one-time token.
            if let storedToken: BearerToken = tokenStorage.tokenFor(client: clientConfiguration, authorization: authorization),
                storedToken.isValid {
                // The in-flight refresh already persisted its result (store precedes release).
                makeRequestByApplyingAuthorizationHeader(to: request, with: storedToken, completion: completion)
                return
            }
            logger.info("Token refresh already in flight in this process; waiting to reuse its result")
            // The completion notification is unbuffered; a missed wake costs one short interval, not the full lock timeout.
            waitForRefreshThenResumeOnce(timeout: min(0.5, tokenRefreshLockRelinquishInterval),
                                         request: request, completion: completion)
            return
        }
        // Re-read after acquiring the claim: refresh the current stored token, never a pre-claim snapshot.
        guard let currentToken: BearerToken = tokenStorage.tokenFor(client: clientConfiguration, authorization: authorization) else {
            logger.warn("Token disappeared while acquiring the refresh claim (e.g. logout); failing request")
            OAuth2RefreshClaimRegistry.shared.release(key: claimKey, generation: claimGeneration)
            completion(.error(OAuth2Error.internalFailure))
            return
        }
        if currentToken.isValid {
            logger.info("Another refresh completed while acquiring the claim; reusing its token")
            OAuth2RefreshClaimRegistry.shared.release(key: claimKey, generation: claimGeneration)
            makeRequestByApplyingAuthorizationHeader(to: request, with: currentToken, completion: completion)
            return
        }
        performRefresh(of: currentToken, claimKey: claimKey, claimGeneration: claimGeneration,
                       request: request, completion: completion)
    }

    /// waitForRefresh can invoke its handler from both the timeout and the completion notification when
    /// they race; collapse to a single re-entry so the request completion can never fire twice.
    private func waitForRefreshThenResumeOnce(timeout: TimeInterval, request: URLRequest,
                                              completion: @escaping (Result<URLRequest>) -> Void) {
        let resumeLock = NSLock()
        var resumed = false
        OAuth2TokenRefreshCoordinator.shared.waitForRefresh(timeout: timeout) {
            resumeLock.lock()
            let alreadyResumed = resumed
            resumed = true
            resumeLock.unlock()
            if alreadyResumed {
                return
            }
            self.prepareForTransport(request: request, completion: completion)
        }
    }

    /// Issues the refresh grant and resumes the request: persist, unlock, release claim, then wake waiters — in that order.
    private func performRefresh(of token: BearerToken, claimKey: String, claimGeneration: UInt64,
                                request: URLRequest, completion: @escaping (Result<URLRequest>) -> Void) {
        tokenStorage.lockRefreshToken(timeout: tokenRefreshLockRelinquishInterval, client: clientConfiguration, authorization: authorization)
        logger.info("Token is expired, proceeding to refresh token")
        OAuth2TokenRefreshCoordinator.shared.beginTokenRefresh()

        refresh(token: token) { result in
            switch result {
            case .error(let error):
                logger.warn("There was an error refreshing the token")
                // A superseded holder must not delete the successor's token or unlock its lock.
                if OAuth2RefreshClaimRegistry.shared.owns(key: claimKey, generation: claimGeneration) {
                    if case OAuth2Error.clientFailure = error {
                        self.tokenStorage.removeTokenFor(client: self.clientConfiguration, authorization: self.authorization)
                    }
                    tokenStorage.unlockRefreshTokenFor(client: clientConfiguration, authorization: authorization)
                }
                OAuth2RefreshClaimRegistry.shared.release(key: claimKey, generation: claimGeneration)
                completion(.error(error))
            case .value(let newToken):
                logger.info("Successfully refreshed token")
                logger.debug("New token issued: \(newToken)")
                // Persist before releasing the claim or waking waiters; a superseded holder must not
                // overwrite the successor's newer token or unlock its lock.
                if OAuth2RefreshClaimRegistry.shared.owns(key: claimKey, generation: claimGeneration) {
                    self.tokenStorage.store(token: newToken, for: self.clientConfiguration, with: self.authorization)
                    tokenStorage.unlockRefreshTokenFor(client: clientConfiguration, authorization: authorization)
                }
                OAuth2RefreshClaimRegistry.shared.release(key: claimKey, generation: claimGeneration)

                /// Resume original request using freshly obtained bearer token
                self.makeRequestByApplyingAuthorizationHeader(to: request, with: newToken, completion: completion)
            }
            OAuth2TokenRefreshCoordinator.shared.endTokenRefresh()
        }
    }

    private func prepareForTransportWithClientAuthorization(request: URLRequest, completion: @escaping (Result<URLRequest>) -> Void) {
        logger.verbose("No bearer token found, but client authorization is requested.")
        if authorization.type == .bearer {
            // Issue new token with client username/password and then apply bearer header
            issueTokenForClientUser { result in
                switch result {
                case .error(let error):
                    logger.warn("There was an error issuing the new client token")
                    self.tokenStorage.removeTokenFor(client: self.clientConfiguration, authorization: self.authorization)
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
            let basicToken = BasicToken(username: clientConfiguration.clientIdentifier,
                                        password: clientConfiguration.clientSecret)
            makeRequestByApplyingAuthorizationHeader(to: request,
                                                     with: basicToken,
                                                     completion: completion)
        }
    }

    private func issueTokenForClientUser(_ completion: @escaping Result<BearerToken>.Block) {
        // If guest user credentials exist, we attempt a password grant
        // Otherwise, we attempt a client_credentials grant
        logger.verbose("About to issue a new client bearer token...")
        let authenticationStrategy: OAuth2TokenGrantStrategy

        if let username = clientConfiguration.guestUsername,
            let password = clientConfiguration.guestPassword {
            logger.verbose("Guest user credentials exist. Attempting password grant...")
            authenticationStrategy = OAuth2PasswordTokenGrantStrategy(username: username, password: password, clientConfiguration: clientConfiguration)
        }
        else {
            logger.verbose("Guest user credentials do not exist. Attempting client_credentials grant...")
            authenticationStrategy = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: clientConfiguration)
        }
        Auth.Migrator.notifyTokenPreFetchHooksWith(token: nil, client: clientConfiguration, authorizationLevel: authorization.level)

        authenticationStrategy.issueToken(completion: completion)
    }

    private func makeRequestByApplyingAuthorizationHeader(to request: URLRequest, with token: OAuth2Token, completion: Result<URLRequest>.Block) {
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

    private func refresh(token: BearerToken, completion: @escaping Result<BearerToken>.Block) {
        Auth.Migrator.notifyTokenPreFetchHooksWith(token: token, client: clientConfiguration, authorizationLevel: authorization.level)
        guard let refreshToken = token.refreshToken else {
            logger.warn([
                "A request required Bearer authorization, but the expired token",
                "does not have an available refresh token"
                ].joined(separator: " "))
            completion(.error(OAuth2Error.internalFailure))
            return
        }

        guard let factory = refreshStrategyFactory else {
            logger.warn("Refresh strategy is nil; aborting refresh_token grant")
            completion(.error(OAuth2Error.internalFailure))
            return
        }

        let grant = factory.make(refreshToken: refreshToken, clientConfiguration: clientConfiguration)

        grant.issueToken { result in
            completion(result)
            Auth.Migrator.notifyTokenPostFetchHooksWith(client: self.clientConfiguration,
                                                        authorizationLevel: self.authorization.level,
                                                        result: result)
        }
    }

}
