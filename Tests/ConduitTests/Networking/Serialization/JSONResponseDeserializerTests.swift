//
//  JSONResponseDeserializerTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class JSONResponseDeserializerTests: XCTestCase {

    var deserializer: JSONResponseDeserializer!
    let validResponseHeaders = ["Content-Type": "application/json"]
    var validResponseData: Data!
    var validResponse: URLResponse!

    override func setUp() {
        super.setUp()

        guard let validResponseData = "{\"key\" : \"value\"}".data(using: .utf8) else {
            XCTFail()
            return
        }
        guard let url = URL(string: "http://localhost:3333") else {
            XCTFail()
            return
        }
        guard let validResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: validResponseHeaders) else {
            XCTFail()
            return
        }

        self.validResponseData = validResponseData
        self.validResponse = validResponse
        deserializer = JSONResponseDeserializer()
    }

    func testThrowsErrorForEmptyResponse() {
        XCTAssertThrowsError(try deserializer.deserialize(response: nil, data: validResponseData), "throws .noResponse") { error in
            guard case ResponseDeserializerError.noResponse = error else {
                XCTFail()
                return
            }
        }
    }

    func testThrowsErrorForUnacceptableContentTypes() throws {
        func makeResponse(contentType: String? = nil) throws -> HTTPURLResponse {
            var headerFields: [String: String]? = nil
            if let contentType = contentType {
                headerFields = ["Content-Type": contentType]
            }
            let url = try URL(absoluteString: "http://localhost:3333")
            guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: headerFields) else {
                throw TestError.invalidTest
            }
            return response
        }
        let invalidResponses = try ["application/xml", "text/html", "text/plain", nil].map { try makeResponse(contentType: $0) }

        for invalidResponse in invalidResponses {
            XCTAssertThrowsError(try deserializer.deserialize(response: invalidResponse, data: validResponseData), "throws .badResponse") { error in
                guard case ResponseDeserializerError.badResponse(_) = error else {
                    XCTFail()
                    return
                }
            }
        }

        let validResponse = try makeResponse(contentType: "application/json")
        let deserializedObj = try? deserializer.deserialize(response: validResponse, data: validResponseData)
        XCTAssert(deserializedObj != nil)
    }

    func testDeserializesToJSON() {
        guard let obj = try? deserializer.deserialize(response: validResponse, data: validResponseData),
            let json = obj as? [String: String] else {
            XCTFail()
            return
        }

        XCTAssert(json == ["key": "value"])
    }

    func testAllowsFragmentedJSON() {
        guard let fragmentedJSONStringData = "\"someperson@test.com\"".data(using: String.Encoding.utf8),
            let fragmentedJSONNumberData = "3.14".data(using: String.Encoding.utf8),
            let fragmentedJSONNullData = "null".data(using: String.Encoding.utf8) else {
                XCTFail()
                return
        }

        func validateThrowsFor(_ data: Data) {
            XCTAssertThrowsError(try deserializer.deserialize(response: validResponse, data: data), "throws .deserializationFailure") { error in
                guard case ResponseDeserializerError.deserializationFailure = error else {
                    XCTFail()
                    return
                }
            }
        }

        func validatePassesFor(_ data: Data) {
            let json = try? deserializer.deserialize(response: validResponse, data: data)
            XCTAssert(json != nil)
        }

        let fragments = [fragmentedJSONStringData, fragmentedJSONNumberData, fragmentedJSONNullData]

        fragments.forEach(validateThrowsFor)

        deserializer = JSONResponseDeserializer(readingOptions: .allowFragments)

        fragments.forEach(validatePassesFor)
    }

}
