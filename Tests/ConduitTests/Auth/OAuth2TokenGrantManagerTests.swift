//
//  OAuth2TokenGrantManagerTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class OAuth2TokenGrantManagerTests: XCTestCase {

    typealias BadResponse = (response: HTTPURLResponse?, expectedError: OAuth2Error)

    let dummyURL = URL(string: "http://localhost:3333/get")

    func testErrorsGeneratedAsExpected() {
        guard let url = dummyURL else {
            XCTFail("Inavlid url")
            return
        }
        let response401 = HTTPURLResponse(url: url, statusCode: 401, httpVersion: "1.1", headerFields: nil)
        let response400 = HTTPURLResponse(url: url, statusCode: 400, httpVersion: "1.1", headerFields: nil)
        let response500 = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "1.1", headerFields: nil)

        guard let errorNoResponse = OAuth2TokenGrantManager.errorFrom(data: nil, response: nil) as? OAuth2Error,
            let error401 = OAuth2TokenGrantManager.errorFrom(data: nil, response: response401) as? OAuth2Error,
            let error400 = OAuth2TokenGrantManager.errorFrom(data: nil, response: response400) as? OAuth2Error,
            let error500 = OAuth2TokenGrantManager.errorFrom(data: nil, response: response500) as? OAuth2Error else {
                XCTFail("Unexpected error type")
                return
        }

        guard case .noResponse = errorNoResponse,
            case .clientFailure(_, _) = error401,
            case .clientFailure(_, _) = error400,
            case .serverFailure(_, _) = error500 else {
                XCTFail("Unexpected error type")
                return
        }

    }

    func testValidResponseGeneratesNoErrors() {
        guard let url = dummyURL else {
            XCTFail("Inavlid url")
            return
        }
        let validResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let generatedError = OAuth2TokenGrantManager.errorFrom(data: nil, response: validResponse)
        XCTAssertNil(generatedError)
    }

    func testBadResponses() {
        guard let url = dummyURL, let mockResponse = HTTPURLResponse(url: url, statusCode: 401, httpVersion: "1.1", headerFields: nil) else {
            XCTFail("Invalid response")
            return
        }

        let badResponses = [
            (nil, OAuth2Error.noResponse),
            (HTTPURLResponse(url: url, statusCode: 401, httpVersion: "1.1", headerFields: nil), OAuth2Error.clientFailure(nil, mockResponse)),
            (HTTPURLResponse(url: url, statusCode: 400, httpVersion: "1.1", headerFields: nil), OAuth2Error.clientFailure(nil, mockResponse)),
            (HTTPURLResponse(url: url, statusCode: 500, httpVersion: "1.1", headerFields: nil), OAuth2Error.serverFailure(nil, mockResponse))
        ]

        badResponses.forEach { badResponse in
            let generatedError = OAuth2TokenGrantManager.errorFrom(data: nil, response: badResponse.0)
            XCTAssertNotNil(generatedError)
        }
    }
}
