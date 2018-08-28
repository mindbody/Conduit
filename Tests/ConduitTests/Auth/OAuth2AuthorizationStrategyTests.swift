//
//  OAuth2AuthorizationStrategyTests.swift
//  Conduit
//
//  Created by Anthony Lipscomb on 8/28/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class OAuth2AuthorizationStrategyTests: XCTestCase {

    let redirectURI = "x-oauth2-myapp://authorize"
    let customParameters: [String: String] = ["some_id": "123abc"]
    let clientIdentifier: String = "Conduit"
    let scope = "private_read,write"

    private func makeStrategy() throws -> MockSafariAuthorizationStrategy {
        return MockSafariAuthorizationStrategy()
    }

    func testAuthorize() throws {
        var request = OAuth2AuthorizationRequest(clientIdentifier: clientIdentifier)
        request.redirectURI = try URL(absoluteString: redirectURI)
        request.scope = scope
        request.state = AuthTestUtilities.makeSecureRandom(length: 32)
        request.clientSecret = "shhh, it's a secret"
        request.additionalParameters = customParameters

        let expect = expectation(description: "Expect the query parameters to be returned in the header of the resposne")

        var response: OAuth2AuthorizationResponse!
        try makeStrategy().authorize(request: request) { authorizeResponse in
            XCTAssertNil(authorizeResponse.error)
            response = authorizeResponse.value
            expect.fulfill()
        }

        wait(for: [expect], timeout: TimeInterval(5))
        XCTAssertNotNil(response.code)
        XCTAssert(response.queryItems?.contains { $0 == "scope" && $1 == scope } == true)
        XCTAssertEqual(response.state, request.state)
    }
}
