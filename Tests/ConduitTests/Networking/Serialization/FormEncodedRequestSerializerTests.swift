//
//  FormEncodedRequestSerializerTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class FormEncodedRequestSerializerTests: XCTestCase {

    var request: URLRequest!
    var serializer: FormEncodedRequestSerializer!

    override func setUp() {
        super.setUp()

        guard let url = URL(string: "http://localhost:3333") else {
            XCTFail("Invalid url")
            return
        }

        request = URLRequest(url: url)
        request.httpMethod = "POST"
        serializer = FormEncodedRequestSerializer()
    }

    func testURIEncodesBodyParameters() {
        let tests: [([String: String], [String])] = [
            (["foo": "bar"], ["foo=bar"]),
            (["foo": "bar", "bing": "bang"], ["foo=bar", "bing=bang"])
        ]

        for test in tests {
            let serializedRequest = try? serializer.serialize(request: request, bodyParameters: test.0)
            guard let body = serializedRequest?.httpBody else {
                XCTFail("Expected body")
                return
            }
            let resultBodyString = String(data: body, encoding: .utf8)
            for expectation in test.1 {
                XCTAssert(resultBodyString?.contains(expectation) == true)
            }
        }
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

    func testEncodesPlusSymbolsByDefault() {
        let parameters = [
            "foo": "bar+baz"
        ]

        let serializedRequest = try? serializer.serialize(request: request, bodyParameters: parameters)
        guard let body = serializedRequest?.httpBody else {
            XCTFail("Expected body")
            return
        }
        let resultBodyString = String(data: body, encoding: .utf8)

        XCTAssert(resultBodyString == "foo=bar%2Bbaz")
    }

}
