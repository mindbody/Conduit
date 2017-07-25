//
//  NetworkReachabilityTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//
#if !os(Linux)

import XCTest
@testable import Conduit

class NetworkReachabilityTests: XCTestCase {

    var reachability: NetworkReachability!

    override func setUp() {
        super.setUp()

        reachability = NetworkReachability(hostName: "google.com")
    }

    func testImmediatelyStartsPollingReachabilityOnEventRegistration() {
        reachability.register { _ in }
        XCTAssert(reachability.isPollingReachability == true)
    }

}

#endif
