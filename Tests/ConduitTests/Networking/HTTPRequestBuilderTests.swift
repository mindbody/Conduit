//
//  HTTPRequestBuilderTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

private class MockRequestSerializer: RequestSerializer {
    var shouldThrowError = false
    var hasBeenUtilized = false

    func serialize(request: URLRequest, bodyParameters: Any?) throws -> URLRequest {
        self.hasBeenUtilized = true

        if shouldThrowError {
            throw MockSerializationError.testError
        }

        return request
    }
}

class HTTPRequestBuilderTests: XCTestCase {

    private func makeRequestBuilder() throws -> HTTPRequestBuilder {
        let url = try URL(absoluteString: "http://localhost:3333")
        return HTTPRequestBuilder(url: url)
    }

    func testGeneratesBasicRequests() throws {
        let sut = try makeRequestBuilder()
        let request = try? sut.build()
        XCTAssertNotNil(request)
    }

    func testUsesProvidedRequestSerializer() throws {
        let sut = try makeRequestBuilder()
        let mockSerializer = MockRequestSerializer()

        sut.serializer = mockSerializer
        guard let request = try? sut.build() else {
            XCTFail("Failed to build the request")
            return
        }

        XCTAssert(request.url == sut.url)
        XCTAssert(mockSerializer.hasBeenUtilized)
    }

    func testForwardsErrorsFromSerializer() throws {
        let sut = try makeRequestBuilder()
        let mockSerializer = MockRequestSerializer()
        mockSerializer.shouldThrowError = true

        sut.serializer = mockSerializer
        XCTAssertThrowsError(try sut.build(), "error forwarded") { error in
            guard case MockSerializationError.testError = error else {
                XCTFail("Unexpeted error was thrown")
                return
            }
        }
    }

    func testAppliesAdditionalHeadersToRequests() throws {
        let sut = try makeRequestBuilder()
        sut.headers = [
            "SomeHeader": "SomeValue",
            "OtherHeader": "OtherValue"
        ]
        guard let request = try? sut.build() else {
            XCTFail("Failed to build the request")
            return
        }

        XCTAssert(request.value(forHTTPHeaderField: "SomeHeader") == "SomeValue")
        XCTAssert(request.value(forHTTPHeaderField: "OtherHeader") == "OtherValue")
    }

    func testIgnoresQueryParamsIfPercentEncodedParamsAreSet() throws {
        let sut = try makeRequestBuilder()
        sut.percentEncodedQuery = "key1=value+1&key2=value%202"
        sut.queryStringParameters = [
            "key3": "key4"
        ]

        guard let request = try? sut.build() else {
            XCTFail("Failed to build the request")
            return
        }

        XCTAssert(request.url?.absoluteString.contains("key1=value+1&key2=value%202") == true)
        XCTAssert(request.url?.absoluteString.contains("key3=key4") == false)
    }

}
