//
//  HTTPRequestSerializerTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

extension HTTPRequestSerializerTests {
    static var allTests: [(String, (HTTPRequestSerializerTests) -> () throws -> Void)] = {
        return [
            ("testAddsRequiredW3Headers", testAddsRequiredW3Headers),
            ("testRejectsBodyParametersForConflictingHTTPVerbs", testRejectsBodyParametersForConflictingHTTPVerbs)
        ]
    }()
}

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
        guard let serializedRequest = try? serializer.serialize(request: request, bodyParameters: nil) else {
            XCTFail()
            return
        }
        let allHTTPHeaderKeys = serializedRequest.allHTTPHeaderFields?.keys.map { $0 }
        for key in headerKeys {
            XCTAssert(allHTTPHeaderKeys?.contains(key) == true)
        }
    }

    func testRejectsBodyParametersForConflictingHTTPVerbs() {
        func validateThrowsFor(_ method: HTTPRequestBuilder.Method) {
            var request: URLRequest! = self.request
            request.httpMethod = method.rawValue

            do {
                _ = try serializer.serialize(request: request, bodyParameters: ["foo": "bar"])
                XCTFail()
            }
            catch let error {
                guard case RequestSerializerError.httpVerbDoesNotAllowBodyParameters = error else {
                    XCTFail()
                    return
                }
            }
        }

        func validatePassesFor(_ method: HTTPRequestBuilder.Method) {
            var request: URLRequest! = self.request
            request.httpMethod = method.rawValue
            let serializedRequest = try? serializer.serialize(request: request, bodyParameters: ["foo": "bar"])
            XCTAssert(serializedRequest != nil)
        }

        let validHTTPMethods: [HTTPRequestBuilder.Method] = [.CONNECT, .DELETE, .OPTIONS, .POST, .PUT, .PATCH, .TRACE]
        let invalidHTTPMethods: [HTTPRequestBuilder.Method] = [.GET, .HEAD]

        validHTTPMethods.forEach(validatePassesFor)
        invalidHTTPMethods.forEach(validateThrowsFor)
    }

}
