//
//  OAuth2PasswordTokenGrantTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class OAuth2PasswordTokenGrantTests: XCTestCase {

    var mockServerEnvironment: OAuth2ServerEnvironment!
    var mockClientConfiguration: OAuth2ClientConfiguration!
    let username = "username"
    let password = "hunter2"
    let passwordGrantType = "password"
    let customParameters: [String : String] = [
        "some_id": "123abc"
    ]

    override func setUp() {
        super.setUp()

        do {
            mockServerEnvironment = OAuth2ServerEnvironment(tokenGrantURL: try URL(absoluteString: "http://localhost:3333/get"))
            mockClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "herp", clientSecret: "derp",
                                                                environment: mockServerEnvironment, guestUsername: "clientuser", guestPassword: "abc123")
        }
        catch {
            XCTFail()
        }
    }

    private func makeStrategy() -> OAuth2PasswordTokenGrantStrategy {
        var strategy = OAuth2PasswordTokenGrantStrategy(username: username, password: password, clientConfiguration: mockClientConfiguration)
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

            XCTAssert(bodyParameters["grant_type"] == passwordGrantType)
            XCTAssert(bodyParameters["username"] == username)
            XCTAssert(bodyParameters["password"] == password)
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
