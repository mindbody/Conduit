//
//  XMLTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class XMLTests: XCTestCase {

    /// Test structure:
    /// <?xml version="1.0" encoding="utf-8"?>
    /// <Root>
    ///   </N>
    ///   <N>test 🙂 value</N>
    ///   <N>
    ///     <N testKey=\"testValue\"/>
    ///     <LastNode/>
    ///   </N>
    /// </Root>

    let xmlString = "<?xml version=\"1.0\" encoding=\"utf-8\"?><Root><N/><N>test 🙂 value</N><N><N testKey=\"testValue\"/><LastNode/></N></Root>"

    private func validate(xml: XML) {
        XCTAssert(xml.root?.name == "Root")
        XCTAssert(xml.root?.children.count == 3)
        XCTAssert(xml.root?.children.first?.isLeaf == true)
        XCTAssert(xml.root?.children[1].value == "test 🙂 value")
        XCTAssert(xml.root?.children.last?.isLeaf == false)
        XCTAssert(xml.root?.children.last?.children.count == 2)
        guard let attributes = xml.root?.children.last?.children.first?.attributes else {
            XCTFail()
            return
        }
        XCTAssert(attributes == ["testKey": "testValue"])
        XCTAssert(xml.root?.children.last?.children.last?.name == "LastNode")
    }

    func testXMLNodeConstruction() {
        var n4 = XMLNode(name: "N")
        n4.attributes = ["testKey": "testValue"]
        let n5 = XMLNode(name: "LastNode")

        let n1 = XMLNode(name: "N")
        var n2 = XMLNode(name: "N")
        n2.value = "test 🙂 value"
        var n3 = XMLNode(name: "N")
        n3.children = [n4, n5]

        var root = XMLNode(name: "Root")
        root.children = [n1, n2, n3]

        let xml = XML(root: root)

        validate(xml: xml)
    }

    func testXMLStringConstruction() {
        guard let xml = XML(xmlString: xmlString) else {
            XCTFail()
            return
        }
        validate(xml: xml)
    }

    func testXMLStringOutputReconstruction() {
        guard let originalXML = XML(xmlString: xmlString),
            let xml = XML(xmlString: originalXML.xmlValue()) else {
                XCTFail()
                return
        }
        validate(xml: xml)
    }

}
