//
//  JSONRequestSerializerTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class JSONRequestSerializerTests: XCTestCase {

    var request: URLRequest!
    var serializer: JSONRequestSerializer!
    let testJSONParameters = ["key1": "value1", "key2": 2, "key3": ["nested": true]] as [String : Any]

    override func setUp() {
        super.setUp()

        guard let url = URL(string: "http://localhost:3333") else {
            XCTFail("Inavlid url")
            return
        }

        request = URLRequest(url: url)
        request.httpMethod = "POST"
        serializer = JSONRequestSerializer()
    }

    func testSerializesJSONObject() {
        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: testJSONParameters) else {
            XCTFail("Serialization failed")
            return
        }

        guard let httpBody = modifiedRequest.httpBody else {
            XCTFail("Expected body")
            return
        }

        let json = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String : Any]
        XCTAssert(json != nil)
    }

    func testAllowsFragmentedJSON() {
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

    func testConfiguresDefaultContentTypeHeader() {
        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: nil) else {
            XCTFail("Serialization failed")
            return
        }

        XCTAssert(modifiedRequest.allHTTPHeaderFields?["Content-Type"] == "application/json")
    }

    func testDoesntReplaceCustomDefinedHeaders() {
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
