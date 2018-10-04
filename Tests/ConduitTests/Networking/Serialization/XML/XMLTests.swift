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

    let xmlString = """
        <?xml version="1.0" encoding="utf-8"?><Root><N/><N>test 🙂 value</N><N><N testKey="testValue"/><LastNode/></N></Root>
        """

    private func validate(xml: XML) {
        XCTAssert(xml.root?.name == "Root")
        XCTAssert(xml.root?.children.count == 3)
        XCTAssert(xml.root?.children.first?.isLeaf == true)
        XCTAssert(xml.root?.children[1].getValue() == "test 🙂 value")
        XCTAssert(xml.root?.children.last?.isLeaf == false)
        XCTAssert(xml.root?.children.last?.children.count == 2)
        guard let attributes = xml.root?.children.last?.children.first?.attributes else {
            XCTFail("No attributes")
            return
        }
        XCTAssertEqual(attributes["testKey"], "testValue")
        XCTAssertEqual(xml.root?.children.last?.children.last?.name, "LastNode")
    }

    func testXMLNodeConstruction() {
        let node4 = XMLNode(name: "N")
        node4.attributes["testKey"] = "testValue"
        let node5 = XMLNode(name: "LastNode")

        let node1 = XMLNode(name: "N")
        let node2 = XMLNode(name: "N")
        node2.text = "test 🙂 value"
        let node3 = XMLNode(name: "N")
        node3.children = [node4, node5]

        let root = XMLNode(name: "Root")
        root.children = [node1, node2, node3]

        let xml = XML(root: root)

        validate(xml: xml)
    }

    func testXMLStringConstruction() {
        guard let xml = XML(xmlString) else {
            XCTFail("Failed to parse string")
            return
        }
        validate(xml: xml)
    }

    func testXMLStringOutputReconstruction() {
        guard let originalXML = XML(xmlString), let xml = XML(originalXML.description) else {
            XCTFail("Failed to parse xml")
            return
        }
        validate(xml: xml)
    }

    func testXMLNodeStringConstruction() {
        let string = "<foo><bar>baz</bar></foo>"
        let node = XMLNode(string)
        XCTAssertEqual(node?.name, "foo")
        XCTAssertEqual(node?["bar"]?.getValue(), "baz")
        XCTAssertEqual(node?.description, string)
    }

    func testXMLNodeStringConstructionWithGenerics() {
        let string = "<xml><int>1</int><double>12.34</double><bool>true</bool></xml>"
        let node = XMLNode(string)
        XCTAssertEqual(node?.name, "xml")
        XCTAssertEqual(node?.getValue("int"), 1)
        XCTAssertEqual(node?.getValue("double"), 12.34)
        XCTAssertEqual(node?.getValue("bool"), true)
    }

    func testLosslessStringConvertibleEmpty() {
        let xml = ""
        XCTAssertNil(XML(xml))
    }

    func testXMLInjection() {
        let xml = "<Node><Parent><Child>Foo</Child></Parent></Node>"
        let node = XML(xml)
        let parent = node?.root?.nodes(named: "Parent", traversal: .breadthFirst).first
        parent?.children.append(XMLNode(name: "Child", value: "Bar"))
        XCTAssertEqual(node?.description, "<?xml version=\"1.0\" encoding=\"utf-8\"?><Node><Parent><Child>Foo</Child><Child>Bar</Child></Parent></Node>")
    }

    func testXMLReplacement() {
        let xml = "<Node><Parent><Child>Foo</Child></Parent></Node>"
        let node = XML(xml)
        let parent = node?.root?.nodes(named: "Parent", traversal: .breadthFirst).first
        parent?.children = [XMLNode(name: "Child", value: "Bar")]
        XCTAssertEqual(node?.description, "<?xml version=\"1.0\" encoding=\"utf-8\"?><Node><Parent><Child>Bar</Child></Parent></Node>")
    }

    func testXMLDeletion() {
        let xml = "<Node><Parent><Child>Foo</Child></Parent></Node>"
        let node = XML(xml)
        let parent = node?.root?.nodes(named: "Parent", traversal: .breadthFirst).first
        parent?.children = []
        XCTAssertEqual(node?.description, "<?xml version=\"1.0\" encoding=\"utf-8\"?><Node><Parent/></Node>")
    }

}
