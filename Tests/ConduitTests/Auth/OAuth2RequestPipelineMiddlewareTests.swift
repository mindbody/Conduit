//
//  OAuth2RequestPipelineMiddlewareTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

extension OAuth2RequestPipelineMiddlewareTests {
    static var allTests: [(String, (OAuth2RequestPipelineMiddlewareTests) -> () throws -> Void)] = {
        return [
            ("testAppliesBearerHeaderIfValidTokenExists", testAppliesBearerHeaderIfValidTokenExists),
            ("testRefreshesBearerTokenIfExpired", testRefreshesBearerTokenIfExpired),
            ("testAttemptsPasswordGrantWithGuestCredentialsIfTheyExist", testAttemptsPasswordGrantWithGuestCredentialsIfTheyExist),
            ("testAttemptsClientCredentialsGrantIfGuestCredentialsDontExist", testAttemptsClientCredentialsGrantIfGuestCredentialsDontExist),
            ("testFailsForBearerUserAuthIfNoTokenExists", testFailsForBearerUserAuthIfNoTokenExists),
            ("testNotifiesMigratorPreAndPostFetchTokenHooksForRefreshes", testNotifiesMigratorPreAndPostFetchTokenHooksForRefreshes)
        ]
    }()
}

class OAuth2RequestPipelineMiddlewareTests: XCTestCase {

    var mockServerEnvironment: OAuth2ServerEnvironment!
    var validServerEnvironment: OAuth2ServerEnvironment!

    var tokenStorage: OAuth2TokenStore!

    var validClientConfiguration: OAuth2ClientConfiguration!
    var mockClientConfiguration: OAuth2ClientConfiguration!

    let validClientID = "test_client"
    let validClientSecret = "test_secret"
    let guestUsername = "test_user"
    let guestPassword = "hunter2"

    let randomTokenAccessToken = "abc123!!"

    override func setUp() {
        super.setUp()

        tokenStorage = OAuth2TokenMemoryStore()

        do {
            mockServerEnvironment = OAuth2ServerEnvironment(scope: "urn:everything", tokenGrantURL: try URL(absoluteString: "http://localhost:3333/get"))
            mockClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "herp", clientSecret: "derp", environment: mockServerEnvironment,
                                                                guestUsername: "clientuser", guestPassword: "abc123")

            validServerEnvironment = OAuth2ServerEnvironment(scope: "all the things",
                                                             tokenGrantURL: try URL(absoluteString: "http://localhost:5000/oauth2/issue/token"))
            validClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: validClientID, clientSecret: validClientSecret,
                                                                 environment: validServerEnvironment)
        }
        catch {
            XCTFail()
        }
    }

    private func makeDummyRequest() throws -> URLRequest {
        let requestBuilder = HTTPRequestBuilder(url: try URL(absoluteString: "http://localhost:3333/post"))
        requestBuilder.bodyParameters = ["key": "value"]
        requestBuilder.method = .POST
        requestBuilder.serializer = JSONRequestSerializer()

        return try requestBuilder.build()
    }

    func testAppliesBearerHeaderIfValidTokenExists() throws {
        let randomToken = BearerToken(accessToken: randomTokenAccessToken, refreshToken: "notused", expiration: Date().addingTimeInterval(1_000_000))
        let authorization = OAuth2Authorization(type: .bearer, level: .user)

        tokenStorage.store(token: randomToken, for: validClientConfiguration, with: authorization)

        let request = try makeDummyRequest()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let decorateRequestExpectation = expectation(description: "request immediately decorated")
        sut.prepareForTransport(request: request) { result in
            guard case .value(let request) = result else {
                XCTFail()
                return
            }
            XCTAssert(request.allHTTPHeaderFields?["Authorization"] == randomToken.authorizationHeaderValue)
            decorateRequestExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }

    func testRefreshesBearerTokenIfExpired() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let request = try makeDummyRequest()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let refreshTokenExpectation = expectation(description: "token refreshed")

        let clientCredentialsStrategy = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: validClientConfiguration)
        clientCredentialsStrategy.issueToken { result in
            guard let token = result.value else {
                XCTFail()
                return
            }
            let expiredToken = BearerToken(accessToken: token.accessToken, refreshToken: token.refreshToken, expiration: Date())

            self.tokenStorage.store(token: expiredToken, for: self.validClientConfiguration, with: authorization)

            sut.prepareForTransport(request: request) { result in
                guard let request = result.value else {
                    XCTFail()
                    return
                }
                let authorizationHeader = request.allHTTPHeaderFields?["Authorization"]
                XCTAssert(authorizationHeader?.contains("Bearer") == true)
                XCTAssert(authorizationHeader != expiredToken.accessToken)

                refreshTokenExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2)
    }

    func testAttemptsPasswordGrantWithGuestCredentialsIfTheyExist() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .client)

        let request = try makeDummyRequest()
        validClientConfiguration.guestUsername = "test_user"
        validClientConfiguration.guestPassword = "hunter2"
        var sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let tokenFetchedExpectation = expectation(description: "token fetched")
        sut.prepareForTransport(request: request) { result in
            guard case .value(let request) = result else {
                XCTFail()
                return
            }
            XCTAssert(request.allHTTPHeaderFields?["Authorization"]?.contains("Bearer") == true)
            tokenFetchedExpectation.fulfill()
        }

        /// Update guest user creds to prove code flow

        validClientConfiguration.guestUsername = "invalid_user"
        validClientConfiguration.guestPassword = "invalid_pass"
        sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let tokenFetchAttemptedExpectation = expectation(description: "token fetch failed")
        sut.prepareForTransport(request: request) { result in
            XCTAssert(result.error != nil)
            tokenFetchAttemptedExpectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testAttemptsClientCredentialsGrantIfGuestCredentialsDontExist() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .client)

        let request = try makeDummyRequest()
        var sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let tokenFetchedExpectation = expectation(description: "token fetched")
        sut.prepareForTransport(request: request) { result in
            guard case .value(let request) = result else {
                XCTFail()
                return
            }
            XCTAssert(request.allHTTPHeaderFields?["Authorization"]?.contains("Bearer") == true)
            tokenFetchedExpectation.fulfill()
        }

        /// Update client creds to prove code flow

        validClientConfiguration.clientIdentifier = "invalid_client"
        validClientConfiguration.clientSecret = "invalid_secret"
        sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let tokenFetchAttemptedExpectation = expectation(description: "token fetch failed")
        sut.prepareForTransport(request: request) { result in
            XCTAssert(result.error != nil)
            tokenFetchAttemptedExpectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFailsForBearerUserAuthIfNoTokenExists() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)

        let request = try makeDummyRequest()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)
        let decorationFailedExpectation = expectation(description: "decoration failed")

        sut.prepareForTransport(request: request) { result in
            XCTAssert(result.error != nil)
            decorationFailedExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.1)
    }

    func testNotifiesMigratorPreAndPostFetchTokenHooksForRefreshes() throws {
        let clientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "one-use-client", clientSecret: "hunter2", environment: mockServerEnvironment)

        let randomToken = BearerToken(accessToken: randomTokenAccessToken, refreshToken: "notused", expiration: Date())
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        tokenStorage.store(token: randomToken, for: clientConfiguration, with: authorization)

        let request = try makeDummyRequest()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let calledPreFetchHookExpectation = expectation(description: "called pre-fetch hook")
        let calledPostFetchHookExpectation = expectation(description: "called pre-fetch hook")

        Auth.Migrator.registerPreFetchHook { client, _  in
            if client.clientIdentifier == clientConfiguration.clientIdentifier {
                calledPreFetchHookExpectation.fulfill()
            }
        }

        Auth.Migrator.registerPostFetchHook { client, _, _  in
            if client.clientIdentifier == clientConfiguration.clientIdentifier {
                calledPostFetchHookExpectation.fulfill()
            }
        }

        sut.prepareForTransport(request: request, completion: { _ in })

        waitForExpectations(timeout: 1)
    }
}
