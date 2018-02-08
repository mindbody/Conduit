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

    typealias BadResponse = (response: HTTPURLResponse?, expectedError: ConduitError)

    let dummyURL = URL(string: "http://localhost:3333/get")

    func testErrorsGeneratedAsExpected() {
        guard let url = dummyURL else {
            XCTFail("Inavlid url")
            return
        }
        let noResponse = SessionTaskResponse()
        let response401 = SessionTaskResponse(response: HTTPURLResponse(url: url, statusCode: 401, httpVersion: "1.1", headerFields: nil))
        let response400 = SessionTaskResponse(response: HTTPURLResponse(url: url, statusCode: 400, httpVersion: "1.1", headerFields: nil))
        let response500 = SessionTaskResponse(response: HTTPURLResponse(url: url, statusCode: 500, httpVersion: "1.1", headerFields: nil))

        guard let errorNoResponse = OAuth2TokenGrantManager.errorFrom(taskResponse: noResponse),
            let error401 = OAuth2TokenGrantManager.errorFrom(taskResponse: response401),
            let error400 = OAuth2TokenGrantManager.errorFrom(taskResponse: response400),
            let error500 = OAuth2TokenGrantManager.errorFrom(taskResponse: response500) else {
                XCTFail("Unexpected error type")
                return
        }

        guard case .noResponse = errorNoResponse,
            case .requestFailure = error401,
            case .requestFailure = error400,
            case .requestFailure = error500 else {
                XCTFail("Unexpected error type")
                return
        }

    }

    func testValidResponseGeneratesNoErrors() {
        guard let url = dummyURL else {
            XCTFail("Inavlid url")
            return
        }
        let taskResponse = SessionTaskResponse(response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil))
        let generatedError = OAuth2TokenGrantManager.errorFrom(taskResponse: taskResponse)
        XCTAssertNil(generatedError)
    }

}
