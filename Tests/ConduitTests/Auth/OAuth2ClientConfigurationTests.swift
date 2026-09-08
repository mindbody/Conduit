//
//  OAuth2ClientConfigurationTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class OAuth2ClientConfigurationTests: XCTestCase {

    let environment = OAuth2ServerEnvironment(scope: "baz", tokenGrantURL: URL(fileURLWithPath: "baz.com"))

    func testConfidentialClientByDefault() {
        let configuration = OAuth2ClientConfiguration(clientIdentifier: "foo", clientSecret: "bar",
                                                      environment: environment)
        XCTAssertFalse(configuration.isPublicClient)
        XCTAssertEqual(configuration.clientSecret, "bar")
    }

    func testPublicClientHasNoSecret() {
        let configuration = OAuth2ClientConfiguration(publicClientIdentifier: "foo", environment: environment)
        XCTAssertTrue(configuration.isPublicClient)
        XCTAssertEqual(configuration.clientIdentifier, "foo")
        XCTAssertTrue(configuration.clientSecret.isEmpty)
    }

    func testEquality() {
        XCTAssertEqual(OAuth2ClientConfiguration(clientIdentifier: "foo", clientSecret: "bar",
                                                 environment: environment),
                       OAuth2ClientConfiguration(clientIdentifier: "foo", clientSecret: "bar",
                                                 environment: environment))
    }

    func testInequality() {
        XCTAssertNotEqual(OAuth2ClientConfiguration(clientIdentifier: "foo", clientSecret: "bar",
                                                    environment: environment),
                          OAuth2ClientConfiguration(clientIdentifier: "foo2", clientSecret: "bar",
                                                    environment: environment))

        XCTAssertNotEqual(OAuth2ClientConfiguration(clientIdentifier: "foo", clientSecret: "bar",
                                                    environment: environment),
                          OAuth2ClientConfiguration(clientIdentifier: "foo", clientSecret: "bar2",
                                                    environment: environment))
    }

}
