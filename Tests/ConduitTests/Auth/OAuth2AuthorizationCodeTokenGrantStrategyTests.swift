//
//  OAuth2AuthorizationCodeTokenGrantStrategyTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class OAuth2AuthorizationCodeTokenGrantStrategyTests: XCTestCase {

    let authCode = "hunter2"
    let redirectURI = "x-oauth2-myapp://authorize?scope=read,write"
    let authorizationCodeGrantType = "authorization_code"
    let customParameters: [String: String] = ["some_id": "123abc"]

    private func makeStrategy() throws -> OAuth2AuthorizationCodeTokenGrantStrategy {
        let mockServerEnvironment = OAuth2ServerEnvironment(tokenGrantURL: try URL(absoluteString: "http://localhost:3333/get"))
        let mockClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "herp", clientSecret: "derp",
                                                                environment: mockServerEnvironment, guestUsername: "clientuser", guestPassword: "abc123")
        var strategy = OAuth2AuthorizationCodeTokenGrantStrategy(code: authCode, redirectURI: redirectURI, clientConfiguration: mockClientConfiguration)
        strategy.tokenGrantRequestAdditionalBodyParameters = customParameters

        return strategy
    }

    func testAttemptsToIssueTokenViaExtensionGrant() throws {
        let sut = try makeStrategy()

        let request = try sut.buildTokenGrantRequest()
        guard let body = request.httpBody,
            let bodyParameters = AuthTestUtilities.deserialize(urlEncodedParameterData: body),
            let headers = request.allHTTPHeaderFields else {
                XCTFail("Expected header and body")
                return
        }

        XCTAssert(bodyParameters["grant_type"] == authorizationCodeGrantType)
        XCTAssert(bodyParameters["redirect_uri"] == redirectURI)
        XCTAssert(bodyParameters["code"] == authCode)
        for parameter in customParameters {
            XCTAssert(bodyParameters[parameter.key] == parameter.value)
        }
        XCTAssert(request.httpMethod == "POST")
        XCTAssert(headers["Authorization"]?.contains("Basic") == true)
        XCTAssert(bodyParameters["redirect_uri"]?.contains("read,write") == true)
    }

    func testIssuesTokenWithCorrectSessionClient() throws {
        let operationQueue = OperationQueue()
        let sut = try makeStrategy()

        let completionExpectation = expectation(description: "completion handler executed")

        Auth.sessionClient = URLSessionClient(delegateQueue: operationQueue)

        sut.issueToken { result in
            XCTAssertNotNil(result.error)
            XCTAssert(OperationQueue.current == operationQueue)
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testIssuesTokenSync() throws {
        let sut = try makeStrategy()
        Auth.sessionClient = URLSessionClient(delegateQueue: OperationQueue())
        XCTAssertThrowsError(try sut.issueToken())
    }

}
