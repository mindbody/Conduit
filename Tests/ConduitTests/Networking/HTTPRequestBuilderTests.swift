//
//  HTTPRequestBuilderTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

private enum MockSerializationError: Error {
    case testError
}

private class MockRequestSerializer: RequestSerializer {
    var shouldThrowError = false
    var hasBeenUtilized = false

    func serializedRequestWith(request: URLRequest, bodyParameters: Any?, queryParameters: [String : Any]?) throws -> URLRequest {
        self.hasBeenUtilized = true

        if shouldThrowError {
            throw MockSerializationError.testError
        }

        return request
    }
}

class HTTPRequestBuilderTests: XCTestCase {

    var url: URL!
    var sut: HTTPRequestBuilder!

    override func setUp() {
        super.setUp()

        guard let url = URL(string: "http://localhost:3333") else {
            XCTFail()
            return
        }
        self.url = url
        sut = HTTPRequestBuilder(url: url)
    }

    func testGeneratesBasicRequests() {
        let request = try? sut.build()
        XCTAssert(request != nil)
    }

    func testUsesProvidedRequestSerializer() {
        let mockSerializer = MockRequestSerializer()

        sut.serializer = mockSerializer
        guard let request = try? sut.build() else {
            XCTFail()
            return
        }

        XCTAssert(request.url == url)
        XCTAssert(mockSerializer.hasBeenUtilized)
    }

    func testForwardsErrorsFromSerializer() {
        let mockSerializer = MockRequestSerializer()
        mockSerializer.shouldThrowError = true

        sut.serializer = mockSerializer
        XCTAssertThrowsError(try sut.build(), "error forwarded") { error in
            guard case MockSerializationError.testError = error else {
                XCTFail()
                return
            }
        }
    }

    func testAppliesAdditionalHeadersToRequests() {
        sut.headers = [
            "SomeHeader": "SomeValue",
            "OtherHeader": "OtherValue"
        ]
        guard let request = try? sut.build() else {
            XCTFail()
            return
        }

        XCTAssert(request.value(forHTTPHeaderField: "SomeHeader") == "SomeValue")
        XCTAssert(request.value(forHTTPHeaderField: "OtherHeader") == "OtherValue")
    }

    func testIgnoresQueryParamsIfPercentEncodedParamsAreSet() {
        sut.percentEncodedQuery = "key1=value+1&key2=value%202"
        sut.queryStringParameters = [
            "key3": "key4"
        ]

        guard let request = try? sut.build() else {
            XCTFail()
            return
        }

        XCTAssert(request.url?.absoluteString.contains("key1=value+1&key2=value%202") == true)
        XCTAssert(request.url?.absoluteString.contains("key3=key4") == false)
    }

}
