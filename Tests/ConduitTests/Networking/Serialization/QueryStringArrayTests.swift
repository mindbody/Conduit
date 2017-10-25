//
//  QueryStringArrayTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 10/25/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class QueryStringArrayTests: XCTestCase {

    private func makeQueryString() throws -> QueryString {
        let url = try URL(absoluteString: "https://example.com")
        return QueryString(parameters: nil, url: url)
    }

    func testEncodesArraysByIndexing() throws {
        var queryString = try makeQueryString()

        queryString.parameters = ["foo": ["foo", "bar", 1_234, 1.234] ]
        queryString.formattingOptions.arrayFormat = .indexed
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("foo%5B0%5D=foo"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B1%5D=bar"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B2%5D=1234"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B3%5D=1.234"))
    }

    func testEncodesArraysByDuplicatingKeys() throws {
        var queryString = try makeQueryString()

        queryString.parameters = ["foo": ["foo", "bar", 1_234, 1.234] ]
        queryString.formattingOptions.arrayFormat = .duplicatedKeys
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("foo=foo"))
        XCTAssert(encodedURL.absoluteString.contains("foo=bar"))
        XCTAssert(encodedURL.absoluteString.contains("foo=1234"))
        XCTAssert(encodedURL.absoluteString.contains("foo=1.234"))
    }

    func testEncodesArraysWithBrackets() throws {
        var queryString = try makeQueryString()

        queryString.parameters = ["foo": ["foo", "bar", 1_234, 1.234] ]
        queryString.formattingOptions.arrayFormat = .bracketed
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("foo%5B%5D=foo"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B%5D=bar"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B%5D=1234"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B%5D=1.234"))
    }

    func testEncodesArraysWithCommaSeparation() throws {
        var queryString = try makeQueryString()

        queryString.parameters = ["foo": ["foo", "bar", 1_234, 1.234] ]
        queryString.formattingOptions.arrayFormat = .commaSeparated
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("foo=foo,bar,1234,1.234"))
    }

}
