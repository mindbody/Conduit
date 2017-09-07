//
//  ConduitLoggerTests.swift
//  Conduit
//
//  Created by John Hammerlund on 9/6/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
import XCTest
import Conduit

class ConduitLoggerTests: XCTestCase {

    func testLessThan() {
        XCTAssert(LogLevel.noOutput < .error)
        XCTAssert(LogLevel.noOutput < .warn)
        XCTAssert(LogLevel.noOutput < .info)
        XCTAssert(LogLevel.noOutput < .debug)
        XCTAssert(LogLevel.noOutput < .verbose)

        XCTAssertFalse(LogLevel.verbose < .debug)
        XCTAssertFalse(LogLevel.verbose < .info)
        XCTAssertFalse(LogLevel.verbose < .warn)
        XCTAssertFalse(LogLevel.verbose < .error)
        XCTAssertFalse(LogLevel.verbose < .noOutput)
    }

    func testLessThanOrEqual() {
        XCTAssert(LogLevel.noOutput <= .noOutput)
        XCTAssert(LogLevel.noOutput <= .error)
        XCTAssert(LogLevel.noOutput <= .warn)
        XCTAssert(LogLevel.noOutput <= .info)
        XCTAssert(LogLevel.noOutput <= .debug)
        XCTAssert(LogLevel.noOutput <= .verbose)

        XCTAssertFalse(LogLevel.verbose <= .debug)
        XCTAssertFalse(LogLevel.verbose <= .info)
        XCTAssertFalse(LogLevel.verbose <= .warn)
        XCTAssertFalse(LogLevel.verbose <= .error)
        XCTAssertFalse(LogLevel.verbose <= .noOutput)
    }

    func testGreaterThan() {
        XCTAssertFalse(LogLevel.noOutput > .error)
        XCTAssertFalse(LogLevel.noOutput > .warn)
        XCTAssertFalse(LogLevel.noOutput > .info)
        XCTAssertFalse(LogLevel.noOutput > .debug)
        XCTAssertFalse(LogLevel.noOutput > .verbose)

        XCTAssertFalse(LogLevel.noOutput > .error)
        XCTAssertFalse(LogLevel.noOutput > .warn)
        XCTAssertFalse(LogLevel.noOutput > .info)
        XCTAssertFalse(LogLevel.noOutput > .debug)
        XCTAssertFalse(LogLevel.noOutput > .verbose)
    }

    func testGreaterThanOrEqual() {
        XCTAssert(LogLevel.verbose >= .verbose)
        XCTAssert(LogLevel.verbose >= .debug)
        XCTAssert(LogLevel.verbose >= .info)
        XCTAssert(LogLevel.verbose >= .warn)
        XCTAssert(LogLevel.verbose >= .error)
        XCTAssert(LogLevel.verbose >= .noOutput)

        XCTAssertFalse(LogLevel.noOutput >= .error)
        XCTAssertFalse(LogLevel.noOutput >= .warn)
        XCTAssertFalse(LogLevel.noOutput >= .info)
        XCTAssertFalse(LogLevel.noOutput >= .debug)
        XCTAssertFalse(LogLevel.noOutput >= .verbose)
    }

    func testEquals() {
        XCTAssert(LogLevel.verbose == .verbose)

        XCTAssertFalse(LogLevel.verbose == .debug)
    }

}
