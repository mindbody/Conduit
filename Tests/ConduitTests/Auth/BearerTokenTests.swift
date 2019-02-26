//
//  BearerTokenTests.swift
//  Conduit
//
//  Created by John Hammerlund on 6/29/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class BearerTokenTests: XCTestCase {

    let accessToken = "abc123"
    let refreshToken = "hunter2"
    let expiresIn: TimeInterval = 7_200

    lazy var tokenJSON: String = {
        """
        {
          "access_token": "\(accessToken)",
          "refresh_token": "\(refreshToken)",
          "expires_in": \(expiresIn),
          "token_type": "bearer"
        }
        """.replacingOccurrences(of: "\n", with: "")
    }()

    private func validate(token: BearerToken) {
        let expectedExpiration = Date().timeIntervalSince1970 + expiresIn
        let tokenExpiration = token.expiration.timeIntervalSince1970

        XCTAssertEqual(token.accessToken, accessToken)
        XCTAssertEqual(token.refreshToken, refreshToken)
        XCTAssert(abs(tokenExpiration - expectedExpiration) < 5)
    }

    func testEncodesToken() throws {
        let token = BearerToken(accessToken: accessToken, refreshToken: refreshToken, expiration: Date().addingTimeInterval(expiresIn))
        let encoder = JSONEncoder()
        let data = try encoder.encode(token)

        let decoder = JSONDecoder()
        let decodedToken = try decoder.decode(BearerToken.self, from: data)

        validate(token: decodedToken)
    }

    func testMapsFromJSON() throws {
        guard let tokenData = tokenJSON.data(using: .utf8) else {
            XCTFail("Token JSON corrupted")
            return
        }

        guard let json = try JSONSerialization.jsonObject(with: tokenData, options: []) as? [String: Any] else {
            XCTFail("Token JSON corrupted")
            return
        }

        guard let token = BearerToken.mapFrom(JSON: json) else {
            XCTFail("Failed to map token")
            return
        }

        validate(token: token)
    }

    func testMapsTokenWithEmptyExpiration() throws {
        let json = """
        {
        "access_token": "\(accessToken)",
        "refresh_token": "\(refreshToken)",
        "token_type": "bearer"
        }
        """

        guard let tokenData = json.data(using: .utf8) else {
            XCTFail("Token JSON corrupted")
            return
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: tokenData, options: []) as? [String: Any] else {
            XCTFail("Token JSON corrupted")
            return
        }

        guard let token = BearerToken.mapFrom(JSON: jsonObject) else {
            XCTFail("Failed to map token")
            return
        }

        XCTAssertEqual(token.expiration, .distantFuture)
    }

    func testAuthorizationHeaderValue() throws {
        let token = BearerToken(accessToken: accessToken, refreshToken: refreshToken, expiration: Date().addingTimeInterval(expiresIn))

        XCTAssertEqual(token.authorizationHeaderValue, "Bearer \(token.accessToken)")
    }

    func testEquality() {
        let tokenA = BearerToken(accessToken: "foo", refreshToken: "bar", expiration: Date.distantFuture)
        let tokenB = BearerToken(accessToken: "foo", refreshToken: "bar", expiration: Date.distantFuture)
        XCTAssertEqual(tokenA, tokenB)
    }

    func testInequalityForAccessToken() {
        let tokenA = BearerToken(accessToken: "foo1", refreshToken: "bar", expiration: Date.distantFuture)
        let tokenB = BearerToken(accessToken: "foo2", refreshToken: "bar", expiration: Date.distantFuture)
        XCTAssertNotEqual(tokenA, tokenB)
    }

    func testInequalityForRefreshToken() {
        let tokenA = BearerToken(accessToken: "foo", refreshToken: "bar1", expiration: Date.distantFuture)
        let tokenB = BearerToken(accessToken: "foo", refreshToken: "bar2", expiration: Date.distantFuture)
        XCTAssertNotEqual(tokenA, tokenB)
    }

    func testInequalityForExpirationDate() {
        let tokenA = BearerToken(accessToken: "foo", refreshToken: "bar", expiration: Date().addingTimeInterval(1))
        let tokenB = BearerToken(accessToken: "foo", refreshToken: "bar", expiration: Date().addingTimeInterval(2))
        XCTAssertNotEqual(tokenA, tokenB)
    }
}
