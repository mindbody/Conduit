//
//  QueryStringTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

extension QueryStringTests {
    static var allTests: [(String, (QueryStringTests) -> () throws -> Void)] = {
        return [
            ("testHandlesExpectedSerializableTypesWithinFlatDictionary", testHandlesExpectedSerializableTypesWithinFlatDictionary),
            ("testEncodesArraysByIndexing", testEncodesArraysByIndexing),
            ("testEncodesArraysByDuplicatingKeys", testEncodesArraysByDuplicatingKeys),
            ("testEncodesArraysWithBrackets", testEncodesArraysWithBrackets),
            ("testEncodesArraysWithCommaSeparation", testEncodesArraysWithCommaSeparation),
            ("testEncodesDictionariesWithDotNotation", testEncodesDictionariesWithDotNotation),
            ("testEncodesDictionariesWithSubscriptNotation", testEncodesDictionariesWithSubscriptNotation),
            ("testEncodesFragments", testEncodesFragments),
            ("testDoesntEncodePlusSymbolsByDefault", testDoesntEncodePlusSymbolsByDefault),
            ("testReplacesPlusSymbolWithEncodedSpaces", testReplacesPlusSymbolWithEncodedSpaces),
            ("testReplacesPlusSymbolWithEncodedPlusSymbol", testReplacesPlusSymbolWithEncodedPlusSymbol),
            ("testEncodesSpacesByDefault", testEncodesSpacesByDefault),
            ("testEncodesSpacesWithDecodedPlusSymbols", testEncodesSpacesWithDecodedPlusSymbols),
            ("testSpaceEncodingDoesntConflictWithPlusSymbolEncoding", testSpaceEncodingDoesntConflictWithPlusSymbolEncoding),
            ("testDoesntEncodeReservedCharactersByDefault", testDoesntEncodeReservedCharactersByDefault),
            ("testEncodesNonConflictingReservedCharactersWhenSpecified", testEncodesNonConflictingReservedCharactersWhenSpecified)
        ]
    }()
}

class QueryStringTests: XCTestCase {

    var queryString: QueryString!

    override func setUp() {
        super.setUp()

        guard let url = URL(string: "https://google.com") else {
            XCTFail()
            return
        }
        queryString = QueryString(parameters: nil, url: url)
    }

    func testHandlesExpectedSerializableTypesWithinFlatDictionary() {
        /// [String : String]
        /// [String : NSNull]
        /// [String : Int]
        /// [String : Double]
        queryString.parameters = ["foo": "bar"]
        guard let encodedURL1 = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL1.absoluteString.contains("foo=bar"))

        queryString.parameters = ["foo": NSNull()]
        guard let encodedURL2 = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL2.query == "foo")

        queryString.parameters = ["foo": 1_234]
        guard let encodedURL3 = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL3.absoluteString.contains("foo=1234"))

        queryString.parameters = ["foo": 1.234]
        guard let encodedURL4 = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL4.absoluteString.contains("foo=1.234"))
    }

    func testEncodesArraysByIndexing() {
        queryString.parameters = ["foo": ["foo", "bar", 1_234, 1.234] ]
        queryString.formattingOptions.arrayFormat = .indexed
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("foo%5B0%5D=foo"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B1%5D=bar"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B2%5D=1234"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B3%5D=1.234"))
    }

    func testEncodesArraysByDuplicatingKeys() {
        queryString.parameters = ["foo": ["foo", "bar", 1_234, 1.234] ]
        queryString.formattingOptions.arrayFormat = .duplicatedKeys
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("foo=foo"))
        XCTAssert(encodedURL.absoluteString.contains("foo=bar"))
        XCTAssert(encodedURL.absoluteString.contains("foo=1234"))
        XCTAssert(encodedURL.absoluteString.contains("foo=1.234"))
    }

    func testEncodesArraysWithBrackets() {
        queryString.parameters = ["foo": ["foo", "bar", 1_234, 1.234] ]
        queryString.formattingOptions.arrayFormat = .bracketed
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("foo%5B%5D=foo"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B%5D=bar"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B%5D=1234"))
        XCTAssert(encodedURL.absoluteString.contains("foo%5B%5D=1.234"))
    }

    func testEncodesArraysWithCommaSeparation() {
        queryString.parameters = ["foo": ["foo", "bar", 1_234, 1.234] ]
        queryString.formattingOptions.arrayFormat = .commaSeparated
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("foo=foo,bar,1234,1.234"))
    }

    func testEncodesDictionariesWithDotNotation() {
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
            XCTFail()
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("param1.key1=value1"))
        XCTAssert(encodedURL.absoluteString.contains("param1.key2=2"))
        XCTAssert(encodedURL.absoluteString.contains("param2.nested.key4=3.45"))
        XCTAssert(encodedURL.absoluteString.contains("param2.array=1"))
        XCTAssert(encodedURL.absoluteString.contains("param2.array=two"))
        XCTAssert(encodedURL.absoluteString.contains("param2.array=3.45"))
    }

    func testEncodesDictionariesWithSubscriptNotation() {
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
            XCTFail()
            return
        }
        XCTAssert(encodedURL.absoluteString.contains("param1%5Bkey1%5D=value1"))
        XCTAssert(encodedURL.absoluteString.contains("param1%5Bkey2%5D=2"))
        XCTAssert(encodedURL.absoluteString.contains("param2%5Bnested%5D%5Bkey4%5D=3.45"))
        XCTAssert(encodedURL.absoluteString.contains("param2%5Barray%5D=1"))
        XCTAssert(encodedURL.absoluteString.contains("param2%5Barray%5D=two"))
        XCTAssert(encodedURL.absoluteString.contains("param2%5Barray%5D=3.45"))
    }

    func testEncodesFragments() {
        queryString.parameters = "hello"
        guard let encodedURL1 = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL1.query == "hello")

        queryString.parameters = 42
        guard let encodedURL2 = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL2.query == "42")
    }

    func testDoesntEncodePlusSymbolsByDefault() {
        queryString.parameters = [
            "key1": "value+1"
        ]
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.query == "key1=value+1")
    }

    func testReplacesPlusSymbolWithEncodedSpaces() {
        queryString.parameters = [
            "key1": "value+1"
        ]
        queryString.formattingOptions.plusSymbolEncodingRule = .replacedWithEncodedSpace
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.query == "key1=value%201")
    }

    func testReplacesPlusSymbolWithEncodedPlusSymbol() {
        queryString.parameters = [
            "key1": "value+1"
        ]
        queryString.formattingOptions.plusSymbolEncodingRule = .replacedWithEncodedPlus
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.query == "key1=value%2B1")
    }

    func testEncodesSpacesByDefault() {
        queryString.parameters = [
            "key1": "value 1"
        ]
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.query == "key1=value%201")
    }

    func testEncodesSpacesWithDecodedPlusSymbols() {
        queryString.parameters = [
            "key1": "value 1"
        ]
        queryString.formattingOptions.spaceEncodingRule = .replacedWithDecodedPlus
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.query == "key1=value+1")
    }

    func testSpaceEncodingDoesntConflictWithPlusSymbolEncoding() {
        queryString.parameters = [
            "key1": "value+1",
            "key2": "value 2",
            "key3": "value +3"
        ]
        queryString.formattingOptions.plusSymbolEncodingRule = .replacedWithEncodedSpace
        queryString.formattingOptions.spaceEncodingRule = .replacedWithDecodedPlus
        queryString.formattingOptions.spaceEncodingRule = .replacedWithDecodedPlus
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.query?.contains("key1=value%201") == true)
        XCTAssert(encodedURL.query?.contains("key2=value+2") == true)
        XCTAssert(encodedURL.query?.contains("key3=value+%203") == true)
    }

    func testDoesntEncodeReservedCharactersByDefault() {
        queryString.parameters = [
            "!*'();:@$,/": "!*'();:@$,/"
        ]
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.query?.contains("!*'();:@$,/=!*'();:@$,/") == true)
    }

    func testEncodesNonConflictingReservedCharactersWhenSpecified() {
        queryString.parameters = [
            "!*'();:@$,/&=abc+ ": "!*'();:@$,/&=abc+ "
        ]
        queryString.formattingOptions.percentEncodedReservedCharacterSet = CharacterSet(charactersIn: "!*'();:@$,/&%=abc")
        queryString.formattingOptions.plusSymbolEncodingRule = .replacedWithEncodedSpace
        queryString.formattingOptions.spaceEncodingRule = .replacedWithDecodedPlus
        guard let encodedURL = try? queryString.encodeURL() else {
            XCTFail()
            return
        }
        XCTAssert(encodedURL.query?.contains("%21%2A%27%28%29%3B%3A%40%24%2C%2F%26%3Dabc%20+=%21%2A%27%28%29%3B%3A%40%24%2C%2F%26%3Dabc%20+") == true)
    }
}
