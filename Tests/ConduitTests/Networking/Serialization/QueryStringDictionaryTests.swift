//
//  QueryStringDictionaryTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 10/25/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class QueryStringDictionaryTests: XCTestCase {

    private func makeQueryString() throws -> QueryString {
        let url = try URL(absoluteString: "https://example.com")
        return QueryString(parameters: nil, url: url)
    }

    func testEncodesDictionariesWithDotNotation() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "param1": [
                "key1": "value1",
                "key2": 2
            ],
            "param2": [
                "nested": [
                    "key4": 3.45
                ],
                "array": [
                    1,
                    "two",
                    3.45
                ]
            ]
        ]
        queryString.formattingOptions.arrayFormat = .duplicatedKeys

        queryString.formattingOptions.dictionaryFormat = .dotNotated
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("param1.key1=value1"))
        XCTAssert(encodedURL.absoluteString.contains("param1.key2=2"))
        XCTAssert(encodedURL.absoluteString.contains("param2.nested.key4=3.45"))
        XCTAssert(encodedURL.absoluteString.contains("param2.array=1"))
        XCTAssert(encodedURL.absoluteString.contains("param2.array=two"))
        XCTAssert(encodedURL.absoluteString.contains("param2.array=3.45"))
    }

    func testEncodesDictionariesWithSubscriptNotation() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "param1": [
                "key1": "value1",
                "key2": 2
            ],
            "param2": [
                "nested": [
                    "key4": 3.45
                ],
                "array": [
                    1,
                    "two",
                    3.45
                ]
            ]
        ]
        queryString.formattingOptions.arrayFormat = .duplicatedKeys

        queryString.formattingOptions.dictionaryFormat = .subscripted
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("param1%5Bkey1%5D=value1"))
        XCTAssert(encodedURL.absoluteString.contains("param1%5Bkey2%5D=2"))
        XCTAssert(encodedURL.absoluteString.contains("param2%5Bnested%5D%5Bkey4%5D=3.45"))
        XCTAssert(encodedURL.absoluteString.contains("param2%5Barray%5D=1"))
        XCTAssert(encodedURL.absoluteString.contains("param2%5Barray%5D=two"))
        XCTAssert(encodedURL.absoluteString.contains("param2%5Barray%5D=3.45"))
    }

}
