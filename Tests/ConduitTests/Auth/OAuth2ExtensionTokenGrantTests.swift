//
//  OAuth2ExtensionTokenGrantTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/6/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class OAuth2ExtensionTokenGrantTests: XCTestCase {

    let saml12GrantType = "urn:ietf:params:oauth:grant-type:sam12-bearer"
    let customParameters: [String: String] = ["assertion": "123abc"]

    private func makeStrategy() throws -> OAuth2ExtensionTokenGrantStrategy {
        let mockServerEnvironment = OAuth2ServerEnvironment(tokenGrantURL: try URL(absoluteString: "https://httpbin.org/get"))
        let mockClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "herp", clientSecret: "derp",
                                                                environment: mockServerEnvironment, guestUsername: "clientuser", guestPassword: "abc123")
        let grantType = saml12GrantType

        var strategy = OAuth2ExtensionTokenGrantStrategy(grantType: grantType, clientConfiguration: mockClientConfiguration)
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

        XCTAssert(bodyParameters["grant_type"] == saml12GrantType)
        for parameter in customParameters {
            XCTAssert(bodyParameters[parameter.key] == parameter.value)
        }
        XCTAssert(request.httpMethod == "POST")
        XCTAssert(headers["Authorization"]?.contains("Basic") == true)
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
