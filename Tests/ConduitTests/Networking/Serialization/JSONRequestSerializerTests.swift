//
//  JSONRequestSerializerTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class JSONRequestSerializerTests: XCTestCase {

    let testJSONParameters = ["key1": "value1", "key2": 2, "key3": ["nested": true]] as [String: Any]

    private func makeRequest() throws -> URLRequest {
        let url = try URL(absoluteString: "https://httpbin.org")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }

    func testSerializesJSONObject() throws {
        let request = try makeRequest()
        let serializer = JSONRequestSerializer()

        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: testJSONParameters) else {
            XCTFail("Serialization failed")
            return
        }

        guard let httpBody = modifiedRequest.httpBody else {
            XCTFail("Expected body")
            return
        }

        let json = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
        XCTAssert(json != nil)
    }

    func testAllowsFragmentedJSON() throws {
        let request = try makeRequest()
        let serializer = JSONRequestSerializer()

        let fragmentedBody = "someemail@test.com"
        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: fragmentedBody) else {
            XCTFail("Serialization failed")
            return
        }

        guard let httpBody = modifiedRequest.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) else {
            XCTFail("No body")
            return
        }

        XCTAssert(bodyString == "\"\(fragmentedBody)\"")
    }

    func testConfiguresDefaultContentTypeHeader() throws {
        let request = try makeRequest()
        let serializer = JSONRequestSerializer()

        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: nil) else {
            XCTFail("Serialization failed")
            return
        }

        XCTAssert(modifiedRequest.allHTTPHeaderFields?["Content-Type"] == "application/json")
    }

    func testDoesntReplaceCustomDefinedHeaders() throws {
        var request = try makeRequest()
        let serializer = JSONRequestSerializer()

        let customDefaultHeaderFields = [
            "Accept-Language": "FlyingSpaghettiMonster",
            "User-Agent": "Chromebook. Remember those?",
            "Content-Type": "application/its-not-xml-but-it-kind-of-is-aka-soap"
        ]
        request.allHTTPHeaderFields = customDefaultHeaderFields

        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: nil) else {
            XCTFail("Serialization failed")
            return
        }
        for customHeader in customDefaultHeaderFields {
            XCTAssert(modifiedRequest.value(forHTTPHeaderField: customHeader.0) == customHeader.1)
        }
    }

}
