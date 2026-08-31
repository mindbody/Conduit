//
//  OAuth2MiddlewareRefreshClaimPathTests.swift
//  Conduit
//
//  Copyright © 2026 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

/// Pins the coordinated refresh path's branches: superseded holders must not clobber successor state,
/// and both claim-loss branches must reuse a persisted fresh token instead of issuing a grant.
final class OAuth2MiddlewareRefreshClaimPathTests: XCTestCase {

    private struct SupersededScenarioOutcome {
        let servedAuthorizationHeader: String?
        let storedAccessToken: String?
        let successorLockHeld: Bool
    }

    private func makeClientConfiguration(clientIdentifier: String) throws -> OAuth2ClientConfiguration {
        let serverEnvironment = OAuth2ServerEnvironment(scope: "urn:everything",
                                                        tokenGrantURL: try URL(absoluteString: "https://example.com/oauth2/token"))
        return OAuth2ClientConfiguration(clientIdentifier: clientIdentifier, clientSecret: "test_secret",
                                         environment: serverEnvironment)
    }

    private func claimKeyFor(store: OAuth2TokenStore, clientIdentifier: String) throws -> String {
        try store.tokenIdentifierFor(clientConfiguration: makeClientConfiguration(clientIdentifier: clientIdentifier),
                                     authorization: OAuth2Authorization(type: .bearer, level: .user)) + ".refresh-claim"
    }

    private func makeRequest() throws -> URLRequest {
        let requestBuilder = HTTPRequestBuilder(url: try URL(absoluteString: "https://example.com/api/resource"))
        requestBuilder.method = .GET
        return try requestBuilder.build()
    }

    /// Starts a refresh whose grant is parked on `proceed`, lets its claim go stale, plants successor
    /// state (stolen claim + fresh token + re-locked storage), then releases the parked completion.
    private func runSupersededRefreshScenario(clientIdentifier: String,
                                              gatedFactory: OAuth2RefreshStrategyFactory,
                                              proceed: DispatchSemaphore) throws -> SupersededScenarioOutcome {
        addTeardownBlock { proceed.signal() }
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let clientConfiguration = try makeClientConfiguration(clientIdentifier: clientIdentifier)
        let tokenStorage = OAuth2TokenMemoryStore()
        tokenStorage.store(token: BearerToken(accessToken: "EXPIRED", refreshToken: "RT_OLD", expiration: Date()),
                           for: clientConfiguration, with: authorization)

        var middleware = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration,
                                                         authorization: authorization,
                                                         tokenStorage: tokenStorage)
        middleware.refreshStrategyFactory = gatedFactory
        middleware.tokenRefreshLockRelinquishInterval = 0.05

        let headerLock = NSLock()
        var servedAuthorizationHeader: String?
        let refreshCompleted = expectation(description: "the superseded refresh completes for its own caller")
        middleware.prepareForTransport(request: try makeRequest()) { result in
            headerLock.lock()
            servedAuthorizationHeader = result.value?.value(forHTTPHeaderField: "Authorization")
            headerLock.unlock()
            refreshCompleted.fulfill()
        }

        Thread.sleep(forTimeInterval: 0.1)
        let claimKey = try claimKeyFor(store: tokenStorage, clientIdentifier: clientIdentifier)
        let successorGeneration = try XCTUnwrap(OAuth2RefreshClaimRegistry.shared.tryClaim(key: claimKey, staleAfter: 30),
                                                "the stale claim must be stealable")
        addTeardownBlock {
            OAuth2RefreshClaimRegistry.shared.release(key: claimKey, generation: successorGeneration)
            tokenStorage.unlockRefreshTokenFor(client: clientConfiguration, authorization: authorization)
        }
        tokenStorage.store(token: BearerToken(accessToken: "SUCCESSOR", refreshToken: "RT_NEW",
                                              expiration: Date().addingTimeInterval(3_600)),
                           for: clientConfiguration, with: authorization)
        tokenStorage.lockRefreshToken(timeout: 30, client: clientConfiguration, authorization: authorization)

        proceed.signal()
        waitForExpectations(timeout: 5)

        let stored: BearerToken? = tokenStorage.tokenFor(client: clientConfiguration, authorization: authorization)
        headerLock.lock()
        let header = servedAuthorizationHeader
        headerLock.unlock()
        return SupersededScenarioOutcome(servedAuthorizationHeader: header,
                                         storedAccessToken: stored?.accessToken,
                                         successorLockHeld: tokenStorage.isRefreshTokenLockedFor(client: clientConfiguration,
                                                                                                 authorization: authorization))
    }

    func testSupersededRefreshFailureDoesNotClobberSuccessorState() throws {
        let gatedFactory = GatedFailureStrategyFactory()
        let outcome = try runSupersededRefreshScenario(clientIdentifier: "superseded_failure_client",
                                                       gatedFactory: gatedFactory, proceed: gatedFactory.proceed)

        XCTAssertNil(outcome.servedAuthorizationHeader, "the superseded caller still receives its own clientFailure")
        XCTAssertEqual(outcome.storedAccessToken, "SUCCESSOR", "a superseded clientFailure must not delete the successor's token")
        XCTAssertTrue(outcome.successorLockHeld, "a superseded completion must not unlock the successor's lock")
    }

    func testSupersededRefreshSuccessDoesNotClobberSuccessorState() throws {
        let gatedFactory = GatedSuccessStrategyFactory()
        let outcome = try runSupersededRefreshScenario(clientIdentifier: "superseded_success_client",
                                                       gatedFactory: gatedFactory, proceed: gatedFactory.proceed)

        XCTAssertEqual(outcome.servedAuthorizationHeader, "Bearer LATE", "the superseded caller is still served its own late token")
        XCTAssertEqual(outcome.storedAccessToken, "SUCCESSOR", "a superseded success must not overwrite the successor's newer token")
        XCTAssertTrue(outcome.successorLockHeld, "a superseded completion must not unlock the successor's lock")
    }

    private func runScriptedReadScenario(clientIdentifier: String,
                                         tokenStorage: ScriptedReadTokenStore) throws -> (grants: RecordingRefreshStrategyFactory,
                                                                                          servedAuthorizationHeader: String?) {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let clientConfiguration = try makeClientConfiguration(clientIdentifier: clientIdentifier)
        let grantRecorder = RecordingRefreshStrategyFactory()
        var middleware = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration,
                                                         authorization: authorization,
                                                         tokenStorage: tokenStorage)
        middleware.refreshStrategyFactory = grantRecorder

        var servedHeader: String?
        let requestPrepared = expectation(description: "the caller is served without issuing a grant")
        middleware.prepareForTransport(request: try makeRequest()) { result in
            servedHeader = result.value?.value(forHTTPHeaderField: "Authorization")
            requestPrepared.fulfill()
        }
        waitForExpectations(timeout: 5)
        return (grantRecorder, servedHeader)
    }

    func testWinnerReusesTokenRefreshedWhileAcquiringClaim() throws {
        // Branch-entry read is expired; the post-claim re-read is fresh → serve it, release the claim, no grant.
        let tokenStorage = ScriptedReadTokenStore()
        let outcome = try runScriptedReadScenario(clientIdentifier: "winner_coalesce_client", tokenStorage: tokenStorage)

        XCTAssertEqual(outcome.servedAuthorizationHeader, "Bearer FRESH")
        XCTAssertTrue(outcome.grants.issuedGrantRefreshTokens.isEmpty,
                      "a token refreshed while acquiring the claim must be reused, not refreshed again")

        let claimKey = try claimKeyFor(store: tokenStorage, clientIdentifier: "winner_coalesce_client")
        let reclaimedGeneration = try XCTUnwrap(OAuth2RefreshClaimRegistry.shared.tryClaim(key: claimKey, staleAfter: 30),
                                                "the coalescing winner must release its claim before serving")
        OAuth2RefreshClaimRegistry.shared.release(key: claimKey, generation: reclaimedGeneration)
    }

    func testLoserServesTokenPersistedByInFlightRefresh() throws {
        // A simulated in-flight winner holds the claim; the loser's re-check reads the fresh token → serve, no grant, no wait.
        let tokenStorage = ScriptedReadTokenStore()
        let claimKey = try claimKeyFor(store: tokenStorage, clientIdentifier: "loser_fastpath_client")
        let winnerGeneration = try XCTUnwrap(OAuth2RefreshClaimRegistry.shared.tryClaim(key: claimKey, staleAfter: 30))
        addTeardownBlock {
            OAuth2RefreshClaimRegistry.shared.release(key: claimKey, generation: winnerGeneration)
        }

        let outcome = try runScriptedReadScenario(clientIdentifier: "loser_fastpath_client", tokenStorage: tokenStorage)

        XCTAssertEqual(outcome.servedAuthorizationHeader, "Bearer FRESH")
        XCTAssertTrue(outcome.grants.issuedGrantRefreshTokens.isEmpty,
                      "the loser must reuse the winner's persisted token, never issue its own grant")
        XCTAssertNil(OAuth2RefreshClaimRegistry.shared.tryClaim(key: claimKey, staleAfter: 30),
                     "the loser must not release the in-flight winner's claim")
    }
}
