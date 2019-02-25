//
//  OAuth2ServerEnvironmentTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class OAuth2ServerEnvironmentTests: XCTestCase {

    func testEquality() {
        XCTAssertEqual(OAuth2ServerEnvironment(scope: "foo", tokenGrantURL: URL(fileURLWithPath: "bar")),
                       OAuth2ServerEnvironment(scope: "foo", tokenGrantURL: URL(fileURLWithPath: "bar")))
        XCTAssertEqual(OAuth2ServerEnvironment(tokenGrantURL: URL(fileURLWithPath: "baz")),
                       OAuth2ServerEnvironment(tokenGrantURL: URL(fileURLWithPath: "baz")))
    }

    func testInequality() {
        XCTAssertNotEqual(OAuth2ServerEnvironment(scope: "foo", tokenGrantURL: URL(fileURLWithPath: "bar")),
                          OAuth2ServerEnvironment(scope: "foo2", tokenGrantURL: URL(fileURLWithPath: "bar")))
        XCTAssertNotEqual(OAuth2ServerEnvironment(tokenGrantURL: URL(fileURLWithPath: "baz")),
                          OAuth2ServerEnvironment(tokenGrantURL: URL(fileURLWithPath: "baz2")))
    }

}
