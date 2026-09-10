//
//  OAuth2MiddlewareClientLevelAuthorizationTests.swift
//  Conduit
//
//  Copyright © 2026 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

/// Client-level authorization with no stored token: a confidential client applies its Basic header,
/// while a public client has no secret and must fail before any request is built.
class OAuth2MiddlewareClientLevelAuthorizationTests: XCTestCase {

    private let clientIdentifier = "test_client"

    private func environment() throws -> OAuth2ServerEnvironment {
        OAuth2ServerEnvironment(scope: "all the things",
                                tokenGrantURL: try URL(absoluteString: "http://localhost:5000/oauth2/issue/token"))
    }

    private func confidentialConfiguration() throws -> OAuth2ClientConfiguration {
        OAuth2ClientConfiguration(clientIdentifier: clientIdentifier, clientSecret: "test_secret", environment: try environment())
    }

    private func publicConfiguration() throws -> OAuth2ClientConfiguration {
        OAuth2ClientConfiguration(publicClientIdentifier: clientIdentifier, environment: try environment())
    }

    private func makeDummyRequest() throws -> URLRequest {
        let requestBuilder = HTTPRequestBuilder(url: try URL(absoluteString: "https://httpbingo.org/post"))
        requestBuilder.method = .GET
        return try requestBuilder.build()
    }

    private func prepare(clientConfiguration: OAuth2ClientConfiguration,
                         authorization: OAuth2Authorization) throws -> Result<URLRequest> {
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration,
                                                  authorization: authorization, tokenStorage: OAuth2TokenMemoryStore())
        var outcome: Result<URLRequest>?
        let completionExpectation = expectation(description: "completion handler executed")
        sut.prepareForTransport(request: try makeDummyRequest()) { result in
            outcome = result
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        return try XCTUnwrap(outcome)
    }

    func testConfidentialClientLevelBasicAppliesBasicHeader() throws {
        let result = try prepare(clientConfiguration: try confidentialConfiguration(),
                                 authorization: OAuth2Authorization(type: .basic, level: .client))
        XCTAssertEqual(result.value?.allHTTPHeaderFields?["Authorization"]?.contains("Basic"), true)
    }

    func testPublicClientLevelBasicFailsWithInternalFailure() throws {
        let result = try prepare(clientConfiguration: try publicConfiguration(),
                                 authorization: OAuth2Authorization(type: .basic, level: .client))
        guard let error = result.error, case OAuth2Error.internalFailure = error else {
            return XCTFail("Expected an internalFailure: a public client has no secret to send")
        }
    }

    func testPublicClientLevelBearerWithoutGuestCredentialsFailsWithInternalFailure() throws {
        // The client_credentials grant is reserved for confidential clients (RFC 6749 §4.4).
        let result = try prepare(clientConfiguration: try publicConfiguration(),
                                 authorization: OAuth2Authorization(type: .bearer, level: .client))
        guard let error = result.error, case OAuth2Error.internalFailure = error else {
            return XCTFail("Expected an internalFailure instead of an unauthenticated client_credentials grant")
        }
    }

}
