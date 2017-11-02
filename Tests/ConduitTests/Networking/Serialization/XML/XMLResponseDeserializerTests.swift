//
//  XMLResponseDeserializerTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class XMLResponseDeserializerTests: XCTestCase {

    let validResponseHeaders = ["Content-Type": "application/xml"]

    override func setUp() {
        super.setUp()

    }

    private func makeResonse() throws -> (response: HTTPURLResponse, data: Data) {
        let xml = """
            <?xml version="1.0" encoding="utf-8"?><Root><N/></Root>
            """
        guard let validResponseData = xml.data(using: .utf8) else {
            throw TestError.invalidTest
        }

        guard let url = URL(string: "http://localhost:3333"),
            let validResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: validResponseHeaders) else {
                throw TestError.invalidTest
        }

        return (validResponse, validResponseData)
    }

    func testThrowsErrorForEmptyResponse() throws {
        let deserializer = XMLResponseDeserializer()
        let response = try makeResonse()
        do {
            _ = try deserializer.deserialize(response: nil, data: response.data)
            XCTFail("Expected error")
        }
        catch let error {
            guard case ConduitError.noResponse = error else {
                throw TestError.invalidTest
            }
        }
    }

    func testDeserializesToXML() throws {
        let deserializer = XMLResponseDeserializer()
        let response = try makeResonse()
        guard let obj = try? deserializer.deserialize(response: response.response, data: response.data), let xml = obj as? XML else {
            throw TestError.invalidTest
        }

        XCTAssertEqual(xml.root?.children.first?.name, "N")
    }

}
