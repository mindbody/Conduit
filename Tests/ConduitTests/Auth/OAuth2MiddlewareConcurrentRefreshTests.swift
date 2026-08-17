//
//  OAuth2MiddlewareConcurrentRefreshTests.swift
//  Conduit
//
//  Copyright © 2026 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

/// Two middleware instances sharing one token store race the check-then-act refresh lock; the contract
/// is that concurrent refreshes for the same client/authorization coalesce into a single grant.
final class OAuth2MiddlewareConcurrentRefreshTests: XCTestCase {

    /// Parks the FIRST lock-state reader until a second arrives, deterministically holding both racers
    /// inside the check-then-act window; a lone reader times out after 3s so serialized refreshes still terminate.
    private final class RendezvousTokenStore: OAuth2TokenStore {
        private let underlying = OAuth2TokenMemoryStore()
        /// OAuth2TokenMemoryStore is not thread-safe — serialize access so races corrupt tokens logically, not segfault.
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
            // Read FIRST, rendezvous AFTER (outside the access lock, or the parked reader deadlocks the racer):
            // both racers observe "unlocked" before either writes the lock.
            accessLock.lock()
            let lockExpiration = underlying.refreshTokenLockExpirationFor(client: client, authorization: authorization)
            accessLock.unlock()
            stateLock.lock()
            lockStateReads += 1
            let ordinal = lockStateReads
            stateLock.unlock()
            if ordinal == 1 {
                _ = secondReaderArrived.wait(timeout: .now() + .seconds(3))
            }
            else {
                secondReaderArrived.signal()
            }
            return lockExpiration
        }
    }

    /// Two middleware instances over one store race to refresh the same expired token through the rendezvous-gated window.
    private func runConcurrentRefreshScenario() throws -> (grants: RecordingRefreshStrategyFactory,
                                                           servedAuthorizationHeaders: [String]) {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let serverEnvironment = OAuth2ServerEnvironment(scope: "urn:everything",
                                                        tokenGrantURL: try URL(absoluteString: "https://example.com/oauth2/token"))
        let clientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "coalesce_test_client", clientSecret: "test_secret",
                                                            environment: serverEnvironment)
        let tokenStorage = RendezvousTokenStore()
        let expiredToken = BearerToken(accessToken: "EXPIRED_ACCESS", refreshToken: "RT_OLD", expiration: Date())
        tokenStorage.store(token: expiredToken, for: clientConfiguration, with: authorization)

        let grantRecorder = RecordingRefreshStrategyFactory()
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
        let headerLock = NSLock()
        var servedAuthorizationHeaders: [String] = []

        for middleware in [middlewareA, middlewareB] {
            DispatchQueue.global().async {
                middleware.prepareForTransport(request: request) { result in
                    XCTAssertNotNil(result.value, "both callers must eventually receive an authorized request")
                    if let header = result.value?.value(forHTTPHeaderField: "Authorization") {
                        headerLock.lock()
                        servedAuthorizationHeaders.append(header)
                        headerLock.unlock()
                    }
                    bothRequestsPrepared.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 5)
        return (grantRecorder, servedAuthorizationHeaders)
    }

    func testConcurrentRefreshesAcrossMiddlewareInstancesCoalesceToOneGrant() throws {
        let outcome = try runConcurrentRefreshScenario()

        XCTAssertTrue(outcome.grants.issuedGrantRefreshTokens.allSatisfy { $0 == "RT_OLD" },
                      "grants must only ever spend the token that was current when the refresh began")

        // One token, one spend — every additional grant is a double-spend of a one-time refresh token.
        XCTAssertEqual(outcome.grants.issuedGrantRefreshTokens.count, 1,
                       "concurrent refreshes must coalesce to a single grant; " +
                       "got \(outcome.grants.issuedGrantRefreshTokens.count) grants " +
                       "spending \(Set(outcome.grants.issuedGrantRefreshTokens))")

        // Both callers must be served the winner's fresh token — not the expired one they raced with.
        XCTAssertEqual(outcome.servedAuthorizationHeaders, ["Bearer ACCESS_1", "Bearer ACCESS_1"],
                       "both coalesced callers must carry the single grant's rotated access token")
    }

    func testDisabledCoordinationPreservesLegacyDoubleSpendHazard() throws {
        OAuth2RequestPipelineMiddleware.refreshClaimCoordinationEnabled = false
        defer { OAuth2RequestPipelineMiddleware.refreshClaimCoordinationEnabled = true }

        let outcome = try runConcurrentRefreshScenario()

        // The kill switch must revert to the pre-coordination path exactly, its double-spend hazard included.
        XCTAssertEqual(outcome.grants.issuedGrantRefreshTokens.count, 2,
                       "flag off must run the legacy path byte-for-byte, double-spend included")
        XCTAssertTrue(outcome.grants.issuedGrantRefreshTokens.allSatisfy { $0 == "RT_OLD" },
                      "both legacy grants spend the same one-time token — the double-spend itself")
    }
}
