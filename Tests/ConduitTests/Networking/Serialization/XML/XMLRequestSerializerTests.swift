//
//  XMLRequestSerializerTests.swift
//  Conduit
//
//  Created by John Hammerlund on 6/11/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class XMLRequestSerializerTests: XCTestCase {

    let testXML = XMLNode(name: "xml", children: [
        XMLNode(name: "clients", children: [
            XMLNode(name: "client", children: [
                XMLNode(name: "id", value: "client1"),
                XMLNode(name: "name", value: "Bob"),
                XMLNode(name: "clientonly", value: "Foo")
            ])
        ])
    ])

    let textMalformedXML = XMLNode(name: "xml", children: [
        XMLNode(name: "clients", children: [
            XMLNode(name: "client", children: [
                XMLNode(name: "id", value: "client1"),
                XMLNode(name: "name", value: "Bob"),
                XMLNode(name: "clientonly", value: "Foo"),
                XMLNode(name: "malformed", value: "&-\"-<->-'")
                ])
            ])
        ])

    private func makeRequest() throws -> URLRequest {
        let url = try URL(absoluteString: "http://localhost:3333")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }

    func testSerializesXML() throws {
        let request = try makeRequest()
        let serializer = XMLRequestSerializer()

        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: XML(root: testXML)) else {
            XCTFail("Serialization failed")
            return
        }

        guard let httpBody = modifiedRequest.httpBody,
            let xmlString = String(data: httpBody, encoding: .utf8) else {
            XCTFail("Expected body")
            return
        }

        let xml = XML(xmlString)
        XCTAssert(xml != nil)
    }

    func testMalformedXMLSerializesXML() throws {
        let request = try makeRequest()
        let serializer = XMLRequestSerializer()

        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: XML(root: textMalformedXML)) else {
            XCTFail("Serialization failed")
            return
        }

        guard let httpBody = modifiedRequest.httpBody,
            let xmlString = String(data: httpBody, encoding: .utf8) else {
                XCTFail("Expected body")
                return
        }

        let xml = XML(xmlString)
        let malformedNode = try xml?.root?.node(named: "malformed", traversal: .depthFirst)
        XCTAssertTrue(malformedNode?.xmlString(format: .condensed) == "<malformed>&amp;-&quot;-&lt;-&gt;-&apos;</malformed>")

        XCTAssert(xml != nil)
    }

    func testConfiguresDefaultContentTypeHeader() throws {
        let request = try makeRequest()
        let serializer = XMLRequestSerializer()

        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: nil) else {
            XCTFail("Serialization failed")
            return
        }

        XCTAssert(modifiedRequest.allHTTPHeaderFields?["Content-Type"] == "text/xml; charset=utf-8")
    }

    func testDoesntReplaceCustomDefinedHeaders() throws {
        var request = try makeRequest()
        let serializer = XMLRequestSerializer()

        let customDefaultHeaderFields = [
            "Accept-Language": "FlyingSpaghettiMonster",
            "User-Agent": "Chromebook. Remember those?",
            "Content-Type": "application/its-not-xml-but-it-kind-of-is-aka-soap"
        ]
        request.allHTTPHeaderFields = customDefaultHeaderFields

        guard let modifiedRequest = try? serializer.serialize(request: request, bodyParameters: nil) else {
            XCTFail("Serialization failed")
            return
        }
        for customHeader in customDefaultHeaderFields {
            XCTAssert(modifiedRequest.value(forHTTPHeaderField: customHeader.0) == customHeader.1)
        }
    }

}
