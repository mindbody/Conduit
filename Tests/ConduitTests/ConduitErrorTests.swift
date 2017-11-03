//
//  ConduitErrorTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 11/3/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class ConduitErrorTests: XCTestCase {

    func testInternalError() throws {
        do {
            throw ConduitError.internalFailure(message: "Something went wrong")
        }
        catch ConduitError.internalFailure(let message) {
            XCTAssertEqual(message, "Something went wrong")
        }
    }

    func testNoResponse() throws {
        do {
            guard let url = URL(string: "http://example.com") else {
                throw TestError.invalidTest
            }
            let request = URLRequest(url: url)
            throw ConduitError.noResponse(request: request)
        }
        catch ConduitError.noResponse(let request) {
            XCTAssertEqual(request?.url?.absoluteString, "http://example.com")
        }
    }

    func testRequestFailure() throws {
        do {
            guard let url = URL(string: "http://example.com") else {
                throw TestError.invalidTest
            }
            var taskResponse = SessionTaskResponse()
            taskResponse.request = URLRequest(url: url)
            taskResponse.data = Data()
            taskResponse.error = TestError.someError
            taskResponse.response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            throw ConduitError.requestFailure(taskResponse: taskResponse)
        }
        catch ConduitError.requestFailure(let taskResponse) {
            XCTAssertNotNil(taskResponse.data)
            XCTAssertNotNil(taskResponse.error)
            XCTAssertNotNil(taskResponse.request)
            XCTAssertNotNil(taskResponse.response)
        }
    }

    func testSerializationError() throws {
        do {
            throw ConduitError.serializationError(message: "Failed to serialize")
        }
        catch ConduitError.serializationError(let message) {
            XCTAssertEqual(message, "Failed to serialize")
        }
    }

    func testDeserializationError() throws {
        do {
            throw ConduitError.deserializationError(data: Data(), type: String.self)
        }
        catch ConduitError.deserializationError(let data, let type) {
            XCTAssertNotNil(data)
            XCTAssertEqual(data?.count, 0)
            XCTAssertEqual("\(type)", "String")
        }
    }

}
