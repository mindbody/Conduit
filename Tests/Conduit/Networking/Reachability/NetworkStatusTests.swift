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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testIsPubliclyReachableWhenWWANOrWLANAvailable() {
        var status: NetworkStatus!
#if os(iOS)
        status = NetworkStatus(systemReachabilityFlags: [.connectionRequired, .connectionOnTraffic, .isWWAN, .reachable])
        XCTAssert(status == NetworkStatus.reachableViaWWAN)
        XCTAssert(status.reachable)
#endif

        status = NetworkStatus(systemReachabilityFlags: [.reachable])
        XCTAssert(status == NetworkStatus.reachableViaWLAN)
        XCTAssert(status.reachable)

        status = NetworkStatus(systemReachabilityFlags: [.connectionOnTraffic, .reachable])
        XCTAssert(status == NetworkStatus.reachableViaWLAN)
        XCTAssert(status.reachable)

        status = NetworkStatus(systemReachabilityFlags: [.connectionOnDemand, .reachable])
        XCTAssert(status == NetworkStatus.reachableViaWLAN)
        XCTAssert(status.reachable)
    }

    func testUnreachableWhenReachabilityFlagIsNonexistent() {
        let status = NetworkStatus(systemReachabilityFlags: [.connectionRequired, .connectionOnTraffic, .isDirect])
        XCTAssert(status == NetworkStatus.unreachable)
        XCTAssert(!status.reachable)
    }

    func testReachabilityWithRequiredIntervention() {
        var status = NetworkStatus(systemReachabilityFlags: [.connectionOnDemand, .reachable, .interventionRequired])
        XCTAssert(status == NetworkStatus.reachableWithRequiredIntervention)
        XCTAssert(!status.reachable)

        status = NetworkStatus(systemReachabilityFlags: [.connectionOnTraffic, .reachable, .interventionRequired])
        XCTAssert(status == NetworkStatus.reachableWithRequiredIntervention)
        XCTAssert(!status.reachable)
    }

}
