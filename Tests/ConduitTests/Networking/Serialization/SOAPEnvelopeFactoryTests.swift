//
//  SOAPEnvelopeFactoryTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class SOAPEnvelopeFactoryTests: XCTestCase {

    func testProducesSOAPBodyElements() {
        let sut = SOAPEnvelopeFactory()
        let bodyNode = XMLNode(name: "N")
        let soapBodyNode = sut.makeSOAPBody(root: bodyNode)

        XCTAssertEqual(soapBodyNode.name, "soap:Body")
        XCTAssertEqual(soapBodyNode.children.count, 1)
        XCTAssertEqual(soapBodyNode.children.first?.name, "N")
    }

    func testProducesSOAPEnvelopeElements() {
        let sut = SOAPEnvelopeFactory()
        let envelope = sut.makeSOAPEnvelope()

        XCTAssertEqual(envelope.name, "soap:Envelope")
        XCTAssertEqual(envelope.attributes["xmlns:xsi"], "http://www.w3.org/2001/XMLSchema-instance")
        XCTAssertEqual(envelope.attributes["xmlns:xsd"], "http://www.w3.org/2001/XMLSchema")
        XCTAssertEqual(envelope.attributes["xmlns:soap"], "http://schemas.xmlsoap.org/soap/envelope/")
    }

    func testProducesFormattedSOAPXML() {
        let sut = SOAPEnvelopeFactory()
        let bodyNode = XMLNode(name: "N")
        let soapXML = sut.makeXML(soapBody: bodyNode)

        XCTAssertEqual(soapXML.root?.name, "soap:Envelope")
        XCTAssertEqual(soapXML.root?.children.count, 1)
        XCTAssertEqual(soapXML.root?["soap:Body"]?.children.count, 1)
        XCTAssertNotNil(soapXML.root?["soap:Body"]?["N"])
    }

    func testRespectsCustomPrefixAndRootNamespaceSchema() {
        var sut = SOAPEnvelopeFactory()
        sut.rootNamespaceSchema = "http://clients.mindbodyonline.com/api/0_5"
        sut.soapEnvelopeNamespace = "soapenv"

        let bodyNode = XMLNode(name: "N")
        let soapXML = sut.makeXML(soapBody: bodyNode)

        XCTAssertEqual(soapXML.root?.name, "soapenv:Envelope")
        XCTAssertEqual(soapXML.root?.attributes["xmlns"], "http://clients.mindbodyonline.com/api/0_5")
        XCTAssertEqual(soapXML.root?.children.count, 1)
        XCTAssertEqual(soapXML.root?["soapenv:Body"]?.children.count, 1)
    }

}
