//
//  OAuth2RefreshClaimRegistryTests.swift
//  Conduit
//
//  Copyright © 2026 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

final class OAuth2RefreshClaimRegistryTests: XCTestCase {

    func testFirstClaimWinsAndSecondFailsUntilRelease() throws {
        let registry = OAuth2RefreshClaimRegistry()

        let generation = try XCTUnwrap(registry.tryClaim(key: "clientA:user", staleAfter: 30))
        XCTAssertNil(registry.tryClaim(key: "clientA:user", staleAfter: 30))
        XCTAssertNotNil(registry.tryClaim(key: "clientB:user", staleAfter: 30), "claims are independent per key")

        registry.release(key: "clientA:user", generation: generation)
        XCTAssertNotNil(registry.tryClaim(key: "clientA:user", staleAfter: 30), "released claim is reclaimable")
    }

    func testStaleClaimIsStolen() throws {
        let registry = OAuth2RefreshClaimRegistry()

        XCTAssertNotNil(registry.tryClaim(key: "clientA:user", staleAfter: 0.05))
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertNotNil(registry.tryClaim(key: "clientA:user", staleAfter: 0.05),
                        "a claim older than staleAfter must be stealable so a hung refresh cannot wedge refreshes")
    }

    func testSupersededHolderCannotReleaseSuccessorsClaim() throws {
        let registry = OAuth2RefreshClaimRegistry()

        let staleGeneration = try XCTUnwrap(registry.tryClaim(key: "clientA:user", staleAfter: 0.05))
        Thread.sleep(forTimeInterval: 0.1)
        let liveGeneration = try XCTUnwrap(registry.tryClaim(key: "clientA:user", staleAfter: 30),
                                           "stale claim must be stolen")

        registry.release(key: "clientA:user", generation: staleGeneration)
        XCTAssertNil(registry.tryClaim(key: "clientA:user", staleAfter: 30),
                     "a superseded holder's release must not clear the live successor's claim")

        registry.release(key: "clientA:user", generation: liveGeneration)
        XCTAssertNotNil(registry.tryClaim(key: "clientA:user", staleAfter: 30),
                        "the live holder's release clears the claim")
    }

    func testOwnershipTracksClaimLifecycle() throws {
        let registry = OAuth2RefreshClaimRegistry()

        let staleGeneration = try XCTUnwrap(registry.tryClaim(key: "clientA:user", staleAfter: 0.05))
        XCTAssertTrue(registry.owns(key: "clientA:user", generation: staleGeneration))

        Thread.sleep(forTimeInterval: 0.1)
        let liveGeneration = try XCTUnwrap(registry.tryClaim(key: "clientA:user", staleAfter: 30))
        XCTAssertFalse(registry.owns(key: "clientA:user", generation: staleGeneration),
                       "a holder whose stale claim was stolen no longer owns it")
        XCTAssertTrue(registry.owns(key: "clientA:user", generation: liveGeneration))

        registry.release(key: "clientA:user", generation: liveGeneration)
        XCTAssertFalse(registry.owns(key: "clientA:user", generation: liveGeneration), "released claims are unowned")
    }

    func testExactlyOneWinnerUnderContention() {
        let registry = OAuth2RefreshClaimRegistry()
        let winnerCount = NSLock()
        var winners = 0

        DispatchQueue.concurrentPerform(iterations: 32) { _ in
            if registry.tryClaim(key: "contended", staleAfter: 30) != nil {
                winnerCount.lock()
                winners += 1
                winnerCount.unlock()
            }
        }

        XCTAssertEqual(winners, 1, "tryClaim must be atomic: exactly one of 32 concurrent callers wins")
    }
}
