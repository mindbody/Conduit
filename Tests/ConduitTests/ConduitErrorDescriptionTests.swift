//
//  ConduitErrorDescriptionTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 11/3/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class ConduitErrorDescriptionTests: XCTestCase {

    func testInternalError() {
        do {
            throw ConduitError.internalFailure(message: "Something went wrong")
        }
        catch let error {
            XCTAssertEqual(error.localizedDescription, "Conduit Internal Error: Something went wrong")
        }
    }

    func testNoResponse() {
        do {
            guard let url = URL(string: "http://example.com") else {
                throw TestError.invalidTest
            }
            let request = URLRequest(url: url)
            throw ConduitError.noResponse(request: request)
        }
        catch let error {
            XCTAssertTrue(error.localizedDescription.contains("http://example.com"))
        }
    }

    func testRequestFailure() {
        do {
            guard let url = URL(string: "http://example.com") else {
                throw TestError.invalidTest
            }
            var taskResponse = SessionTaskResponse()
            taskResponse.request = URLRequest(url: url)
            taskResponse.data = Data()
            taskResponse.error = TestError.someError
            taskResponse.response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)
            throw ConduitError.requestFailure(taskResponse: taskResponse)
        }
        catch let error {
            XCTAssertTrue(error.localizedDescription.contains("http://example.com"))
            XCTAssertTrue(error.localizedDescription.contains("401"))
        }
    }

    func testSerializationError() {
        do {
            throw ConduitError.serializationError(message: "Failed to serialize")
        }
        catch let error {
            XCTAssertTrue(error.localizedDescription.contains("Failed to serialize"))
        }
    }

    func testDeserializationError() {
        do {
            let json = ["foo": "bar"]
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            throw ConduitError.deserializationError(data: data, type: String.self)
        }
        catch let error {
            XCTAssertTrue(error.localizedDescription.contains("{\"foo\":\"bar\"}"))
            XCTAssertTrue(error.localizedDescription.contains("String"))
        }
    }

}
