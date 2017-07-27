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

    var sut: SOAPEnvelopeFactory!

    override func setUp() {
        super.setUp()

        sut = SOAPEnvelopeFactory()
    }

    func testProducesSOAPBodyElements() {
        let bodyNode = XMLNode(name: "N")
        let soapBodyNode = sut.makeSOAPBody(root: bodyNode)

        XCTAssert(soapBodyNode.name == "soap:Body")
        XCTAssert(soapBodyNode.children.count == 1)
        XCTAssert(soapBodyNode.children.first?.name == "N")
    }

    func testProducesSOAPEnvelopeElements() {
        let envelope = sut.makeSOAPEnvelope()

        XCTAssert(envelope.name == "soap:Envelope")
        XCTAssert(envelope.attributes["xmlns:xsi"] == "http://www.w3.org/2001/XMLSchema-instance")
        XCTAssert(envelope.attributes["xmlns:xsd"] == "http://www.w3.org/2001/XMLSchema")
        XCTAssert(envelope.attributes["xmlns:soap"] == "http://schemas.xmlsoap.org/soap/envelope/")
    }

    func testProducesFormattedSOAPXML() {
        let bodyNode = XMLNode(name: "N")
        let soapXML = sut.makeXML(soapBody: bodyNode)

        XCTAssert(soapXML.root?.name == "soap:Envelope")
        XCTAssert(soapXML.root?.children.count == 1)
        XCTAssert(soapXML.root?["soap:Body"].first?.children.count == 1)
        XCTAssert(soapXML.root?["soap:Body"]["N"].first != nil)
    }

    func testRespectsCustomPrefixAndRootNamespaceSchema() {
        sut.rootNamespaceSchema = "http://clients.mindbodyonline.com/api/0_5"
        sut.soapEnvelopeNamespace = "soapenv"

        let bodyNode = XMLNode(name: "N")
        let soapXML = sut.makeXML(soapBody: bodyNode)

        XCTAssert(soapXML.root?.name == "soapenv:Envelope")
        XCTAssert(soapXML.root?.attributes["xmlns"] == "http://clients.mindbodyonline.com/api/0_5")
        XCTAssert(soapXML.root?.children.count == 1)
        XCTAssert(soapXML.root?["soapenv:Body"].first?.children.count == 1)
    }

}
