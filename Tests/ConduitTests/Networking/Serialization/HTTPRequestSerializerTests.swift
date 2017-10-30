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

    private func makeRequest() throws -> URLRequest {
        let url = try URL(absoluteString: "http://localhost:3333")
        let request = URLRequest(url: url)
        return request
    }

    func testAddsRequiredW3Headers() throws {
        let request = try makeRequest()
        let serializer = HTTPRequestSerializer()

        let headerKeys = ["Accept-Language", "User-Agent"]
        guard let serializedRequest = try? serializer.serialize(request: request, bodyParameters: nil) else {
            XCTFail("Failed to serialize request")
            return
        }
        let allHTTPHeaderKeys = serializedRequest.allHTTPHeaderFields?.keys.map { $0 }
        for key in headerKeys {
            XCTAssert(allHTTPHeaderKeys?.contains(key) == true)
        }
    }

    func testRejectsBodyParametersForConflictingHTTPVerbs() throws {
        let request = try makeRequest()
        let serializer = HTTPRequestSerializer()

        func validateThrowsFor(_ method: HTTPRequestBuilder.Method) {
            var request = request
            request.httpMethod = method.rawValue

            do {
                _ = try serializer.serialize(request: request, bodyParameters: ["foo": "bar"])
                XCTFail("Expected to fail serializing the request")
            }
            catch let error {
                guard case RequestSerializerError.httpVerbDoesNotAllowBodyParameters = error else {
                    XCTFail("Unexpected error type")
                    return
                }
            }
        }

        func validatePassesFor(_ method: HTTPRequestBuilder.Method) {
            var request = request
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
