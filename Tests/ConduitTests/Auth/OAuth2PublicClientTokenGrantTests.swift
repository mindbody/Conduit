//
//  OAuth2PublicClientTokenGrantTests.swift
//  Conduit
//
//  Copyright © 2026 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

/// A public client sends `client_id` in the body and no `Authorization: Basic` header; a confidential
/// client sends the header and no `client_id`. Pinned across every grant type.
class OAuth2PublicClientTokenGrantTests: XCTestCase {

    let clientIdentifier = "herp"
    let clientSecret = "derp"

    private func environment() throws -> OAuth2ServerEnvironment {
        OAuth2ServerEnvironment(tokenGrantURL: try URL(absoluteString: "https://httpbingo.org/get"))
    }

    private func confidentialConfiguration() throws -> OAuth2ClientConfiguration {
        OAuth2ClientConfiguration(clientIdentifier: clientIdentifier, clientSecret: clientSecret,
                                  environment: try environment())
    }

    private func publicConfiguration() throws -> OAuth2ClientConfiguration {
        OAuth2ClientConfiguration(publicClientIdentifier: clientIdentifier, environment: try environment())
    }

    private func bodyAndHeaders(of request: URLRequest) throws -> ([String: String], [String: String]) {
        guard let body = request.httpBody,
            let bodyParameters = AuthTestUtilities.deserialize(urlEncodedParameterData: body),
            let headers = request.allHTTPHeaderFields else {
                throw OAuth2Error.internalFailure
        }
        return (bodyParameters, headers)
    }

    private func assertPublicShape(_ request: URLRequest, file: StaticString = #file, line: UInt = #line) throws {
        let (bodyParameters, headers) = try bodyAndHeaders(of: request)
        XCTAssertEqual(bodyParameters["client_id"], clientIdentifier, file: file, line: line)
        XCTAssertNil(headers["Authorization"], file: file, line: line)
    }

    private func assertConfidentialShape(_ request: URLRequest, file: StaticString = #file, line: UInt = #line) throws {
        let (bodyParameters, headers) = try bodyAndHeaders(of: request)
        XCTAssertNil(bodyParameters["client_id"], file: file, line: line)
        XCTAssertEqual(headers["Authorization"]?.contains("Basic"), true, file: file, line: line)
    }

    // MARK: - Authorization code

    func testAuthorizationCodeGrantPublicClient() throws {
        let sut = OAuth2AuthorizationCodeTokenGrantStrategy(code: "hunter2", redirectURI: "x-oauth2-myapp://authorize",
                                                            clientConfiguration: try publicConfiguration())
        try assertPublicShape(try sut.buildTokenGrantRequest())
    }

    func testAuthorizationCodeGrantConfidentialClient() throws {
        let sut = OAuth2AuthorizationCodeTokenGrantStrategy(code: "hunter2", redirectURI: "x-oauth2-myapp://authorize",
                                                            clientConfiguration: try confidentialConfiguration())
        try assertConfidentialShape(try sut.buildTokenGrantRequest())
    }

    // MARK: - Refresh token

    func testRefreshTokenGrantPublicClient() throws {
        let sut = OAuth2RefreshTokenGrantStrategy(refreshToken: "refresh-abc", clientConfiguration: try publicConfiguration())
        let request = try sut.buildTokenGrantRequest()
        try assertPublicShape(request)
        let (bodyParameters, _) = try bodyAndHeaders(of: request)
        XCTAssertEqual(bodyParameters["grant_type"], "refresh_token")
        XCTAssertEqual(bodyParameters["refresh_token"], "refresh-abc")
    }

    func testRefreshTokenGrantConfidentialClient() throws {
        let sut = OAuth2RefreshTokenGrantStrategy(refreshToken: "refresh-abc", clientConfiguration: try confidentialConfiguration())
        let request = try sut.buildTokenGrantRequest()
        try assertConfidentialShape(request)
        let (bodyParameters, _) = try bodyAndHeaders(of: request)
        XCTAssertEqual(bodyParameters["grant_type"], "refresh_token")
        XCTAssertEqual(bodyParameters["refresh_token"], "refresh-abc")
    }

    // MARK: - Extension grant (delegation)

    func testExtensionGrantPublicClient() throws {
        var sut = OAuth2ExtensionTokenGrantStrategy(grantType: "delegation", clientConfiguration: try publicConfiguration())
        sut.tokenGrantRequestAdditionalBodyParameters = ["assertion": "123abc"]
        let request = try sut.buildTokenGrantRequest()
        try assertPublicShape(request)
        let (bodyParameters, _) = try bodyAndHeaders(of: request)
        XCTAssertEqual(bodyParameters["grant_type"], "delegation")
        XCTAssertEqual(bodyParameters["assertion"], "123abc")
    }

    func testExtensionGrantConfidentialClient() throws {
        var sut = OAuth2ExtensionTokenGrantStrategy(grantType: "delegation", clientConfiguration: try confidentialConfiguration())
        sut.tokenGrantRequestAdditionalBodyParameters = ["assertion": "123abc"]
        try assertConfidentialShape(try sut.buildTokenGrantRequest())
    }

    // MARK: - Password grant

    func testPasswordGrantPublicClient() throws {
        let sut = OAuth2PasswordTokenGrantStrategy(username: "user", password: "pass",
                                                   clientConfiguration: try publicConfiguration())
        try assertPublicShape(try sut.buildTokenGrantRequest())
    }

    func testPasswordGrantConfidentialClient() throws {
        let sut = OAuth2PasswordTokenGrantStrategy(username: "user", password: "pass",
                                                   clientConfiguration: try confidentialConfiguration())
        try assertConfidentialShape(try sut.buildTokenGrantRequest())
    }

    // MARK: - Client credentials grant

    func testClientCredentialsGrantPublicClient() throws {
        let sut = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: try publicConfiguration())
        try assertPublicShape(try sut.buildTokenGrantRequest())
    }

    func testClientCredentialsGrantConfidentialClient() throws {
        let sut = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: try confidentialConfiguration())
        try assertConfidentialShape(try sut.buildTokenGrantRequest())
    }

}
