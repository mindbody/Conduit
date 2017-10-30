//
//  NetworkReachabilityTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class NetworkReachabilityTests: XCTestCase {

    func testImmediatelyStartsPollingReachabilityOnEventRegistration() {
        let reachability = NetworkReachability(hostName: "google.com")
        reachability?.register { _ in }
        XCTAssertNotNil(reachability)
        XCTAssert(reachability?.isPollingReachability == true)
    }

}
