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

    let validResponseHeaders = ["Content-Type": "application/json"]

    private func makeResponse() throws -> (response: HTTPURLResponse, data: Data) {
        let json = """
            {
                "key": "value"
            }
            """

        guard let validResponseData = json.data(using: .utf8) else {
            throw TestError.invalidTest
        }
        let url = try URL(absoluteString: "http://localhost:3333")
        guard let validResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: validResponseHeaders) else {
            throw TestError.invalidTest
        }

        return (response: validResponse, data: validResponseData)
    }

    private func makeResponse(contentType: String? = nil) throws -> HTTPURLResponse {
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

    func testThrowsErrorForEmptyResponse() throws {
        let response = try makeResponse()
        let deserializer = JSONResponseDeserializer()

        XCTAssertThrowsError(try deserializer.deserialize(response: nil, data: response.data), "throws .noResponse") { error in
            guard case ConduitError.noResponse = error else {
                XCTFail("No response")
                return
            }
        }
    }

    func testThrowsErrorForUnacceptableContentTypes() throws {
        let response = try makeResponse()
        let deserializer = JSONResponseDeserializer()

        let invalidResponses = try ["application/xml", "text/html", "text/plain", nil].map { try makeResponse(contentType: $0) }

        for invalidResponse in invalidResponses {
            XCTAssertThrowsError(try deserializer.deserialize(response: invalidResponse, data: response.data), "throws .badResponse") { error in
                guard case ConduitError.internalFailure = error else {
                    XCTFail(error.localizedDescription)
                    return
                }
            }
        }

        let validResponse = try makeResponse(contentType: "application/json")
        let deserializedObj = try? deserializer.deserialize(response: validResponse, data: response.data)
        XCTAssert(deserializedObj != nil)
    }

    func testDeserializesToJSON() throws {
        let response = try makeResponse()
        let deserializer = JSONResponseDeserializer()

        let obj = try deserializer.deserialize(response: response.response, data: response.data)
        guard let json = obj as? [String: String] else {
            XCTFail("Deserialization failed")
            return
        }

        XCTAssert(json == ["key": "value"])
    }

    func testAllowsFragmentedJSON() throws {
        let response = try makeResponse()
        var deserializer = JSONResponseDeserializer()

        guard let fragmentedJSONStringData = "\"someperson@test.com\"".data(using: String.Encoding.utf8),
            let fragmentedJSONNumberData = "3.14".data(using: String.Encoding.utf8),
            let fragmentedJSONNullData = "null".data(using: String.Encoding.utf8) else {
                XCTFail("Encoding failed")
                return
        }

        func validateThrowsFor(_ data: Data) {
            XCTAssertThrowsError(try deserializer.deserialize(response: response.response, data: data), "throws .deserializationFailure") { error in
                guard case ConduitError.deserializationError = error else {
                    XCTFail(error.localizedDescription)
                    return
                }
            }
        }

        func validatePassesFor(_ data: Data) {
            let json = try? deserializer.deserialize(response: response.response, data: data)
            XCTAssert(json != nil)
        }

        let fragments = [fragmentedJSONStringData, fragmentedJSONNumberData, fragmentedJSONNullData]
        fragments.forEach(validateThrowsFor)

        deserializer = JSONResponseDeserializer(readingOptions: .allowFragments)
        fragments.forEach(validatePassesFor)
    }

}
