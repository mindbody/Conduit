//
//  NetworkStatusTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class NetworkStatusTests: XCTestCase {

    func testIsPubliclyReachableWhenWWANOrWLANAvailable() {
        var status: NetworkStatus

#if os(iOS)
        status = NetworkStatus(systemReachabilityFlags: [.connectionRequired, .connectionOnTraffic, .isWWAN, .reachable])
        XCTAssertEqual(status, NetworkStatus.reachableViaWWAN)
        XCTAssertTrue(status.reachable)
#endif

        status = NetworkStatus(systemReachabilityFlags: [.reachable])
        XCTAssertEqual(status, NetworkStatus.reachableViaWLAN)
        XCTAssertTrue(status.reachable)

        status = NetworkStatus(systemReachabilityFlags: [.connectionOnTraffic, .reachable])
        XCTAssertEqual(status, NetworkStatus.reachableViaWLAN)
        XCTAssertTrue(status.reachable)

        status = NetworkStatus(systemReachabilityFlags: [.connectionOnDemand, .reachable])
        XCTAssertEqual(status, NetworkStatus.reachableViaWLAN)
        XCTAssertTrue(status.reachable)
    }

    func testUnreachableWhenReachabilityFlagIsNonexistent() {
        let status = NetworkStatus(systemReachabilityFlags: [.connectionRequired, .connectionOnTraffic, .isDirect])
        XCTAssertEqual(status, NetworkStatus.unreachable)
        XCTAssertFalse(status.reachable)
    }

    func testReachabilityWithRequiredIntervention() {
        var status = NetworkStatus(systemReachabilityFlags: [.connectionOnDemand, .reachable, .interventionRequired])
        XCTAssertEqual(status, NetworkStatus.reachableWithRequiredIntervention)
        XCTAssertFalse(status.reachable)

        status = NetworkStatus(systemReachabilityFlags: [.connectionOnTraffic, .reachable, .interventionRequired])
        XCTAssertEqual(status, NetworkStatus.reachableWithRequiredIntervention)
        XCTAssertFalse(status.reachable)
    }

}
