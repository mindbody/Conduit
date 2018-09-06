//
//  XMLPrettyPrintTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 9/5/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class XMLPrettyPrintTests: XCTestCase {

    let output = """
            <xml>
                <clients>
                    <client>
                        <id>client1</id>
                        <name>Bob</name>
                        <clientonly>Foo</clientonly>
                        <customers>
                            <customer>
                                <id>customer1</id>
                                <name>Customer Awesome</name>
                            </customer>
                            <customer>
                                <id>customer2</id>
                                <name>Another Customer</name>
                            </customer>
                        </customers>
                    </client>
                    <client>
                        <id>client2</id>
                        <name>Job</name>
                        <clientonly>Bar</clientonly>
                        <customers>
                            <customer>
                                <id>customer3</id>
                                <name>Yet Another Customer</name>
                            </customer>
                        </customers>
                    </client>
                    <client>
                        <id>client3</id>
                        <name>Joe</name>
                        <clientonly>Baz</clientonly>
                    </client>
                </clients>
                <id>root1</id>
                <name>I'm Root</name>
                <rootonly>Root only</rootonly>
            </xml>

            """

    func testXMLNodePrettyPrint() {
        XCTAssertEqual(XMLNodeTests.xml.xmlString(format: .prettyPrinted(spaces: 4)), output)
    }

    func testXMLPrettyPrint() {
        let string = "<Node><Parent><Child>Foo</Child><Child>Bar</Child></Parent></Node>"
        let expectation = """
            <?xml version="1.0" encoding="utf-8"?>
            <Node>
                <Parent>
                    <Child>Foo</Child>
                    <Child>Bar</Child>
                </Parent>
            </Node>
            """

        let xml = XML(string)
        XCTAssertEqual(xml?.xmlString(format: .prettyPrinted(spaces: 4)), expectation)
    }

}
