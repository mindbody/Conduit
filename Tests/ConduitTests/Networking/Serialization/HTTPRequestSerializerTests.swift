//
//  HTTPRequestSerializerTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class HTTPRequestSerializerTests: XCTestCase {

    var request: URLRequest!
    var serializer: HTTPRequestSerializer!

    override func setUp() {
        super.setUp()

        guard let url = URL(string: "http://localhost:3333") else {
            XCTFail()
            return
        }
        request = URLRequest(url: url)
        serializer = HTTPRequestSerializer()
    }

    func testAddsRequiredW3Headers() {
        let headerKeys = ["Accept-Language", "User-Agent"]
        guard let serializedRequest = try? serializer.serializedRequestWith(request: request, bodyParameters: nil, queryParameters: nil) else {
            XCTFail()
            return
        }
        let allHTTPHeaderKeys = serializedRequest.allHTTPHeaderFields?.keys.flatMap { $0 }
        for key in headerKeys {
            XCTAssert(allHTTPHeaderKeys?.contains(key) == true)
        }
    }

    func testRejectsBodyParametersForConflictingHTTPVerbs() {
        func validateThrowsFor(_ method: HTTPRequestBuilder.Method) {
            var request: URLRequest! = self.request
            request.httpMethod = method.rawValue

            XCTAssertThrowsError(try serializer.serializedRequestWith(request: request, bodyParameters: ["foo": "bar"], queryParameters: nil), "throws bad HTTP verb error") { error in
                guard case RequestSerializerError.httpVerbDoesNotAllowBodyParameters = error else {
                    XCTFail()
                    return
                }
            }
        }

        func validatePassesFor(_ method: HTTPRequestBuilder.Method) {
            var request: URLRequest! = self.request
            request.httpMethod = method.rawValue
            let serializedRequest = try? serializer.serializedRequestWith(request: request, bodyParameters: ["foo": "bar"], queryParameters: nil)
            XCTAssert(serializedRequest != nil)
        }

        let validHTTPMethods: [HTTPRequestBuilder.Method] = [.CONNECT, .DELETE, .OPTIONS, .POST, .PUT, .PATCH, .TRACE]
        let invalidHTTPMethods: [HTTPRequestBuilder.Method] = [.GET, .HEAD]

        validHTTPMethods.forEach(validatePassesFor)
        invalidHTTPMethods.forEach(validateThrowsFor)
    }

}
