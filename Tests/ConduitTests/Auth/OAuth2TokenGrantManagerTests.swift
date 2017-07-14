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

    let dummyURL = URL(string: "http://localhost:3333/get")!
    typealias BadResponse = (response: URLResponse?, expectedError: OAuth2Error)
    let mockResponse = HTTPURLResponse(url: URL(string: "http://localhost:3333/get")!, statusCode: 401, httpVersion: "1.1", headerFields: nil)!

    var badResponses: [BadResponse]!


    override func setUp() {
        super.setUp()

        badResponses = [
            (nil, OAuth2Error.noResponse),
            (HTTPURLResponse(url: dummyURL, statusCode: 401, httpVersion: "1.1", headerFields: nil), OAuth2Error.clientFailure(nil, mockResponse)),
            (HTTPURLResponse(url: dummyURL, statusCode: 400, httpVersion: "1.1", headerFields: nil), OAuth2Error.clientFailure(nil, mockResponse)),
            (HTTPURLResponse(url: dummyURL, statusCode: 500, httpVersion: "1.1", headerFields: nil), OAuth2Error.serverFailure(nil, mockResponse))
        ]
    }
    
    func testErrorsGeneratedAsExpected() {
        let response401 = HTTPURLResponse(url: dummyURL, statusCode: 401, httpVersion: "1.1", headerFields: nil)
        let response400 = HTTPURLResponse(url: dummyURL, statusCode: 400, httpVersion: "1.1", headerFields: nil)
        let response500 = HTTPURLResponse(url: dummyURL, statusCode: 500, httpVersion: "1.1", headerFields: nil)

        guard let errorNoResponse = OAuth2TokenGrantManager.errorFrom(data: nil, response: nil) as? OAuth2Error,
            let error401 = OAuth2TokenGrantManager.errorFrom(data: nil, response: response401) as? OAuth2Error,
            let error400 = OAuth2TokenGrantManager.errorFrom(data: nil, response: response400) as? OAuth2Error,
            let error500 = OAuth2TokenGrantManager.errorFrom(data: nil, response: response500) as? OAuth2Error else {
                XCTFail()
                return
        }

        guard case .noResponse = errorNoResponse,
            case .clientFailure(_, _) = error401,
            case .clientFailure(_, _) = error400,
            case .serverFailure(_, _) = error500 else {
                XCTFail()
                return
        }

    }

    func testValidResponseGeneratesNoErrors() {
        let validResponse = HTTPURLResponse(url: dummyURL, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let generatedError = OAuth2TokenGrantManager.errorFrom(data: nil, response: validResponse)
        XCTAssert(generatedError == nil)
    }

}
