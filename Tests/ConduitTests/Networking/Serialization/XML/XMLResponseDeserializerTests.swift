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

    var deserializer: XMLResponseDeserializer!
    let validResponseHeaders = ["Content-Type": "application/xml"]
    var validResponseData: Data!
    var validResponse: HTTPURLResponse!

    override func setUp() {
        super.setUp()

        let xml = """
            <?xml version="1.0" encoding="utf-8"?><Root><N/></Root>
            """
        guard let validResponseData = xml.data(using: .utf8) else {
            XCTFail("Failed to encode string")
            return
        }

        guard let url = URL(string: "http://localhost:3333"),
            let validResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: validResponseHeaders) else {
                XCTFail("Invalid response")
                return
        }

        self.validResponseData = validResponseData
        self.validResponse = validResponse
        deserializer = XMLResponseDeserializer()
    }

    func testThrowsErrorForEmptyResponse() {
        XCTAssertThrowsError(try deserializer.deserialize(response: nil, data: validResponseData), "throws .noResponse") { error in
            guard case ResponseDeserializerError.noResponse = error else {
                XCTFail("Invalid response")
                return
            }
        }
    }

    func testDeserializesToXML() {
        guard let obj = try? deserializer.deserialize(response: validResponse, data: validResponseData), let xml = obj as? XML else {
            XCTFail("Failed to deserialize")
            return
        }

        XCTAssert(xml.root?.children.first?.name == "N")
    }

}
