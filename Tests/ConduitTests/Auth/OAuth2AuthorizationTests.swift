//
//  OAuth2AuthorizationTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class OAuth2AuthorizationTests: XCTestCase {

    func testEquality() {
        XCTAssertEqual(OAuth2Authorization(type: .basic, level: .client),
                       OAuth2Authorization(type: .basic, level: .client))
        XCTAssertEqual(OAuth2Authorization(type: .basic, level: .user),
                       OAuth2Authorization(type: .basic, level: .user))
        XCTAssertEqual(OAuth2Authorization(type: .bearer, level: .client),
                       OAuth2Authorization(type: .bearer, level: .client))
        XCTAssertEqual(OAuth2Authorization(type: .bearer, level: .user),
                       OAuth2Authorization(type: .bearer, level: .user))
    }

    func testInequality() {
        XCTAssertNotEqual(OAuth2Authorization(type: .basic, level: .client),
                          OAuth2Authorization(type: .basic, level: .user))
        XCTAssertNotEqual(OAuth2Authorization(type: .basic, level: .client),
                          OAuth2Authorization(type: .basic, level: .user))
        XCTAssertNotEqual(OAuth2Authorization(type: .basic, level: .client),
                          OAuth2Authorization(type: .bearer, level: .client))
        XCTAssertNotEqual(OAuth2Authorization(type: .basic, level: .user),
                          OAuth2Authorization(type: .bearer, level: .user))
    }

    func testProperties() {
        XCTAssertEqual(OAuth2Authorization(type: .basic, level: .client).type, .basic)
        XCTAssertEqual(OAuth2Authorization(type: .basic, level: .client).level, .client)
        XCTAssertEqual(OAuth2Authorization(type: .bearer, level: .user).type, .bearer)
        XCTAssertEqual(OAuth2Authorization(type: .bearer, level: .user).level, .user)
    }
}
