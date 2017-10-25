//
//  QueryStringTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class QueryStringTests: XCTestCase {

    private func makeQueryString() throws -> QueryString {
        let url = try URL(absoluteString: "https://example.com")
        return QueryString(parameters: nil, url: url)
    }

    func testHandlesExpectedSerializableTypesWithinFlatDictionary() throws {
        var queryString = try makeQueryString()

        /// [String : String]
        queryString.parameters = ["foo": "bar"]
        guard let encodedURL1 = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL1.absoluteString.contains("foo=bar"))

        /// [String : NSNull]
        queryString.parameters = ["foo": NSNull()]
        guard let encodedURL2 = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL2.query == "foo")

        /// [String : Int]
        queryString.parameters = ["foo": 1_234]
        guard let encodedURL3 = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL3.absoluteString.contains("foo=1234"))

        /// [String : Double]
        queryString.parameters = ["foo": 1.234]
        guard let encodedURL4 = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL4.absoluteString.contains("foo=1.234"))
    }

    func testEncodesFragments() throws {
        var queryString = try makeQueryString()

        queryString.parameters = "hello"
        guard let encodedURL1 = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL1.query == "hello")

        queryString.parameters = 42
        guard let encodedURL2 = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL2.query == "42")
    }

    func testEncodesPlusSymbolsByDefault() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "key1": "value+1"
        ]
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.query == "key1=value%2B1")
    }

    func testReplacesPlusSymbolWithEncodedSpaces() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "key1": "value+1"
        ]
        queryString.formattingOptions.plusSymbolEncodingRule = .replacedWithEncodedSpace
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.query == "key1=value%201")
    }

    func testReplacesPlusSymbolWithEncodedPlusSymbol() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "key1": "value+1"
        ]
        queryString.formattingOptions.plusSymbolEncodingRule = .replacedWithEncodedPlus
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.query == "key1=value%2B1")
    }

    func testEncodesSpacesByDefault() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "key1": "value 1"
        ]
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.query == "key1=value%201")
    }

    func testEncodesSpacesWithDecodedPlusSymbols() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "key1": "value 1"
        ]
        queryString.formattingOptions.spaceEncodingRule = .replacedWithDecodedPlus
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.query == "key1=value+1")
    }

    func testSpaceEncodingDoesntConflictWithPlusSymbolEncoding() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "key1": "value+1",
            "key2": "value 2",
            "key3": "value +3"
        ]
        queryString.formattingOptions.plusSymbolEncodingRule = .replacedWithEncodedSpace
        queryString.formattingOptions.spaceEncodingRule = .replacedWithDecodedPlus
        queryString.formattingOptions.spaceEncodingRule = .replacedWithDecodedPlus
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.query?.contains("key1=value%201") == true)
        XCTAssert(encodedURL.query?.contains("key2=value+2") == true)
        XCTAssert(encodedURL.query?.contains("key3=value+%203") == true)
    }

    func testDoesntEncodeReservedCharactersByDefault() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "!*'();:@$,/": "!*'();:@$,/"
        ]
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.query?.contains("!*'();:@$,/=!*'();:@$,/") == true)
    }

    func testEncodesNonConflictingReservedCharactersWhenSpecified() throws {
        var queryString = try makeQueryString()

        queryString.parameters = [
            "!*'();:@$,/&=abc+ ": "!*'();:@$,/&=abc+ "
        ]
        queryString.formattingOptions.percentEncodedReservedCharacterSet = CharacterSet(charactersIn: "!*'();:@$,/&%=abc")
        queryString.formattingOptions.plusSymbolEncodingRule = .replacedWithEncodedSpace
        queryString.formattingOptions.spaceEncodingRule = .replacedWithDecodedPlus
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail("Encoding failed")
            return
        }
        XCTAssert(encodedURL.query?.contains("%21%2A%27%28%29%3B%3A%40%24%2C%2F%26%3Dabc%20+=%21%2A%27%28%29%3B%3A%40%24%2C%2F%26%3Dabc%20+") == true)
    }
}
