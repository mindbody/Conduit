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
    
    var mockServerEnvironment: OAuth2ServerEnvironment!
    var mockClientConfiguration: OAuth2ClientConfiguration!
    let authCode = "hunter2"
    let redirectURI = "x-oauth2-myapp://authorize"
    let authorizationCodeGrantType = "authorization_code"
    let customParameters: [String : String] = [
        "some_id" : "123abc"
    ]

    override func setUp() {
        super.setUp()

        mockServerEnvironment = OAuth2ServerEnvironment(tokenGrantURL: URL(string: "http://localhost:3333/get")!)
        mockClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "herp", clientSecret: "derp", environment: mockServerEnvironment, guestUsername: "clientuser", guestPassword: "abc123")
    }

    private func makeStrategy() -> OAuth2AuthorizationCodeTokenGrantStrategy {
        var strategy = OAuth2AuthorizationCodeTokenGrantStrategy(code: authCode, redirectURI: redirectURI, clientConfiguration: mockClientConfiguration)
        strategy.tokenGrantRequestAdditionalBodyParameters = customParameters

        return strategy
    }

    func testAttemptsToIssueTokenViaExtensionGrant() {
        let sut = makeStrategy()

        do {
            let request = try sut.buildTokenGrantRequest()
            guard let body = request.httpBody,
                let bodyParameters = AuthTestUtilities.deserialize(urlEncodedParameterData: body),
                let headers = request.allHTTPHeaderFields else {
                    XCTFail()
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
        }
        catch {
            XCTFail()
        }
    }

    func testIssuesTokenWithCorrectSessionClient() {
        let operationQueue = OperationQueue()
        let sut = makeStrategy()

        let completionExpectation = expectation(description: "completion handler executed")

        Auth.sessionClient = URLSessionClient(delegateQueue: operationQueue)

        sut.issueToken { _ in
            XCTAssert(OperationQueue.current == operationQueue)
            completionExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

}
