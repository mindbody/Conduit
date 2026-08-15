//
//  OAuth2MiddlewareConcurrentRefreshTests.swift
//  Conduit
//
//  Copyright © 2026 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

/// Reproduces the concurrent-refresh double-spend: two middleware instances sharing one token store
/// both pass the refresh-lock check (check-then-act, no atomicity), and each issues a refresh_token
/// grant with the SAME one-time-use refresh token. Against IdentityServer, the second consume
/// succeeds only inside a 10s grace window; any later straggler gets invalid_grant — which the
/// middleware treats as terminal, deleting the token and force-logging the user out.
///
/// CONTRACT (red until fixed): concurrent refreshes for the same client/authorization must coalesce
/// into a single grant.
final class OAuth2MiddlewareConcurrentRefreshTests: XCTestCase {

    /// Records every grant the middlewares issue and returns rotated tokens like a real token
    /// endpoint. Shared by reference across both middleware instances.
    private final class RecordingRefreshStrategyFactory: OAuth2RefreshStrategyFactory {
        private let recordLock = NSLock()
        private(set) var issuedGrantRefreshTokens: [String] = []

        func make(refreshToken: String, clientConfiguration: OAuth2ClientConfiguration) -> OAuth2TokenGrantStrategy {
            recordLock.lock()
            issuedGrantRefreshTokens.append(refreshToken)
            let rotation = issuedGrantRefreshTokens.count
            recordLock.unlock()
            let rotatedToken = BearerToken(accessToken: "ACCESS_\(rotation)",
                                           refreshToken: "ROTATED_\(rotation)",
                                           expiration: Date().addingTimeInterval(3_600))
            return StubbedGrantStrategy(token: rotatedToken)
        }
    }

    /// Completes asynchronously with a fixed token, mimicking token-endpoint latency.
    private struct StubbedGrantStrategy: OAuth2TokenGrantStrategy {
        let token: BearerToken

        func issueToken(completion: @escaping (Result<BearerToken>) -> Void) {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(50)) {
                completion(.value(token))
            }
        }

        func issueToken() throws -> BearerToken {
            return token
        }
    }

    /// Wraps the memory store and parks the FIRST lock-state reader until a second arrives —
    /// deterministically holding both racers inside the check-then-act window that thread
    /// scheduling opens in production. If refreshes are properly serialized (the fix), the lone
    /// reader times out after 500ms and the test still terminates, green.
    private final class RendezvousTokenStore: OAuth2TokenStore {
        private let underlying = OAuth2TokenMemoryStore()
        /// OAuth2TokenMemoryStore is not thread-safe (unlike the UserDefaults store used in
        /// production) — serialize all underlying access so the racing refreshes corrupt tokens
        /// logically, as in production, instead of segfaulting the process.
        private let accessLock = NSLock()
        private let stateLock = NSLock()
        private var lockStateReads = 0
        private let secondReaderArrived = DispatchSemaphore(value: 0)

        @discardableResult
        func store<Token: OAuth2Token & DataConvertible>(token: Token?, for client: OAuth2ClientConfiguration,
                                                         with authorization: OAuth2Authorization) -> Bool {
            accessLock.lock(); defer { accessLock.unlock() }
            return underlying.store(token: token, for: client, with: authorization)
        }

        func tokenFor<Token: OAuth2Token & DataConvertible>(client: OAuth2ClientConfiguration,
                                                            authorization: OAuth2Authorization) -> Token? {
            accessLock.lock(); defer { accessLock.unlock() }
            return underlying.tokenFor(client: client, authorization: authorization)
        }

        @discardableResult
        func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration,
                              authorization: OAuth2Authorization) -> Bool {
            accessLock.lock(); defer { accessLock.unlock() }
            return underlying.lockRefreshToken(timeout: timeout, client: client, authorization: authorization)
        }

        @discardableResult
        func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
            accessLock.lock(); defer { accessLock.unlock() }
            return underlying.unlockRefreshTokenFor(client: client, authorization: authorization)
        }

        func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date? {
            // Read FIRST, rendezvous AFTER: both racers have then already observed "unlocked" before
            // either writes the lock — the exact interleaving concurrent UserDefaults reads produce
            // in production. The rendezvous (outside the access lock, or the parked reader would
            // deadlock the racer) only makes the scheduler's worst case deterministic.
            accessLock.lock()
            let lockExpiration = underlying.refreshTokenLockExpirationFor(client: client, authorization: authorization)
            accessLock.unlock()
            stateLock.lock()
            lockStateReads += 1
            let ordinal = lockStateReads
            stateLock.unlock()
            if ordinal == 1 {
                _ = secondReaderArrived.wait(timeout: .now() + .milliseconds(500))
            }
            else {
                secondReaderArrived.signal()
            }
            return lockExpiration
        }
    }

    func testConcurrentRefreshesAcrossMiddlewareInstancesCoalesceToOneGrant() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let serverEnvironment = OAuth2ServerEnvironment(scope: "urn:everything",
                                                        tokenGrantURL: try URL(absoluteString: "https://example.com/oauth2/token"))
        let clientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "test_client", clientSecret: "test_secret",
                                                            environment: serverEnvironment)
        let tokenStorage = RendezvousTokenStore()
        let expiredToken = BearerToken(accessToken: "EXPIRED_ACCESS", refreshToken: "RT_OLD", expiration: Date())
        tokenStorage.store(token: expiredToken, for: clientConfiguration, with: authorization)

        let grantRecorder = RecordingRefreshStrategyFactory()
        // Two middleware instances over the same store — the app configures one per URLSessionClient.
        var middlewareA = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration,
                                                          authorization: authorization,
                                                          tokenStorage: tokenStorage)
        middlewareA.refreshStrategyFactory = grantRecorder
        var middlewareB = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration,
                                                          authorization: authorization,
                                                          tokenStorage: tokenStorage)
        middlewareB.refreshStrategyFactory = grantRecorder

        let requestBuilder = HTTPRequestBuilder(url: try URL(absoluteString: "https://example.com/api/resource"))
        requestBuilder.method = .GET
        let request = try requestBuilder.build()

        let bothRequestsPrepared = expectation(description: "both requests complete with a bearer header")
        bothRequestsPrepared.expectedFulfillmentCount = 2

        for middleware in [middlewareA, middlewareB] {
            DispatchQueue.global().async {
                middleware.prepareForTransport(request: request) { result in
                    XCTAssertNotNil(result.value, "both callers must eventually receive an authorized request")
                    bothRequestsPrepared.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 5)

        // Documentation of the spend: every grant that fired presented the same one-time-use token.
        XCTAssertTrue(grantRecorder.issuedGrantRefreshTokens.allSatisfy { $0 == "RT_OLD" },
                      "grants must only ever spend the token that was current when the refresh began")

        // THE CONTRACT (red today): one token, one spend. Every additional grant is a double-spend
        // of a one-time refresh token — the invalid_grant force-logout seed observed in production.
        XCTAssertEqual(grantRecorder.issuedGrantRefreshTokens.count, 1,
                       "concurrent refreshes must coalesce to a single grant; " +
                       "got \(grantRecorder.issuedGrantRefreshTokens.count) grants " +
                       "spending \(Set(grantRecorder.issuedGrantRefreshTokens))")
    }
}
