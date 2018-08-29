//
//  XMLNodeTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 7/26/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

typealias XMLNode = Conduit.XMLNode

class XMLNodeTests: XCTestCase {

    let xml = XMLNode(name: "xml", children: [
        XMLNode(name: "clients", children: [
            XMLNode(name: "client", children: [
                XMLNode(name: "id", value: "client1"),
                XMLNode(name: "name", value: "Bob"),
                XMLNode(name: "clientonly", value: "Foo"),
                XMLNode(name: "customers", children: [
                    XMLNode(name: "customer", children: [
                        XMLNode(name: "id", value: "customer1"),
                        XMLNode(name: "name", value: "Customer Awesome")
                    ]),
                    XMLNode(name: "customer", children: [
                        XMLNode(name: "id", value: "customer2"),
                        XMLNode(name: "name", value: "Another Customer")
                    ])
                ])
            ]),
            XMLNode(name: "client", children: [
                XMLNode(name: "id", value: "client2"),
                XMLNode(name: "name", value: "Job"),
                XMLNode(name: "clientonly", value: "Bar"),
                XMLNode(name: "customers", children: [
                    XMLNode(name: "customer", children: [
                        XMLNode(name: "id", value: "customer3"),
                        XMLNode(name: "name", value: "Yet Another Customer")
                    ])
                ])
            ]),
            XMLNode(name: "client", children: [
                XMLNode(name: "id", value: "client3"),
                XMLNode(name: "name", value: "Joe"),
                XMLNode(name: "clientonly", value: "Baz")
            ])
        ]),
        XMLNode(name: "id", value: "root1"),
        XMLNode(name: "name", value: "I'm Root"),
        XMLNode(name: "rootonly", value: "Root only")
    ])

    let xmlDict: XMLDictionary = [
        "clients": [
            [
                "client": [
                    "id": "client1",
                    "name": "Bob",
                    "clientonly": "Foo",
                    "customers": [
                        [
                            "customer": [
                                "id": "customer1",
                                "name": "Customer Awesome"
                            ]
                        ],
                        [
                            "customer": [
                                "id": "customer2",
                                "name": "Another Customer"
                            ]
                        ]
                    ]
                ]
            ],
            [
                "client": [
                    "id": "client2",
                    "name": "Job",
                    "clientonly": "Bar",
                    "customers": [
                        [
                            "customer": [
                                "id": "customer3",
                                "name": "Yet Another Customer"
                            ]
                        ]
                    ]
                ]
            ],
            [
                "client": [
                    "id": "client3",
                    "name": "Joe",
                    "clientonly": "Baz"
                ]
            ]
        ],
        "id": "root1",
        "name": "I'm Root",
        "rootonly": "Root only"
    ]

    var testSubjects: [XMLNode] {
        return [xml, XMLNode(name: "xml", children: xmlDict)]
    }

    func testSubscripting() {
        for subject in testSubjects {
            XCTAssertEqual(subject["id"]?.getValue(), "root1")
            XCTAssertNotNil(subject["clients"]?["client"]?["id"])
        }
    }

    func testXMLTreeSearch() {
        for subject in testSubjects {
            XCTAssertEqual(subject.name, "xml")
            XCTAssertEqual(subject.nodes(named: "clients", traversal: .breadthFirst).count, 1)
            XCTAssertEqual(subject.nodes(named: "client", traversal: .breadthFirst).count, 3)
            XCTAssertEqual(subject.nodes(named: "customers", traversal: .breadthFirst).count, 2)
            XCTAssertEqual(subject.nodes(named: "customer", traversal: .breadthFirst).count, 3)
            XCTAssertEqual(subject.nodes(named: "id", traversal: .breadthFirst).count, 7)
        }
    }

    func testXMLFirstLevelSearch() throws {
        for subject in testSubjects {
            XCTAssertEqual(subject.nodes(named: "id", traversal: .firstLevel).first?.getValue(), "root1")
            XCTAssertEqual(try subject.getValue("name"), "I'm Root")
            XCTAssertEqual(try subject.getValue("rootonly"), "Root only")
            XCTAssertEqual(try subject.findValue("name", traversal: .firstLevel), "I'm Root")
            XCTAssertEqual(try subject.findValue("rootonly", traversal: .firstLevel), "Root only")
            XCTAssertThrowsError(try subject.getValue("clientonly") as String)
            XCTAssertThrowsError(try subject.findValue("clientonly", traversal: .firstLevel) as String)
        }
    }

    func testXMLDepthTraversal() throws {
        for subject in testSubjects {
            XCTAssertEqual(subject.nodes(named: "id", traversal: .depthFirst).first?.getValue(), "customer1")
            XCTAssertEqual(try subject.findValue("name", traversal: .depthFirst), "Customer Awesome")
            XCTAssertEqual(try subject.findValue("rootonly", traversal: .depthFirst), "Root only")
            XCTAssertEqual(try subject.findValue("clientonly", traversal: .depthFirst), "Foo")
        }
    }

    func testXMLBreadthTraversal() throws {
        for subject in testSubjects {
            XCTAssertEqual(subject.nodes(named: "id", traversal: .breadthFirst).first?.getValue(), "root1")
            XCTAssertEqual(try subject.findValue("name", traversal: .breadthFirst), "I'm Root")
            XCTAssertEqual(try subject.findValue("rootonly", traversal: .breadthFirst), "Root only")
            XCTAssertEqual(try subject.findValue("clientonly", traversal: .breadthFirst), "Foo")
        }
    }

    // swiftlint:disable line_length
    func testXMLOutput() {
        let output = "<xml><clients><client><id>client1</id><name>Bob</name><clientonly>Foo</clientonly><customers><customer><id>customer1</id><name>Customer Awesome</name></customer><customer><id>customer2</id><name>Another Customer</name></customer></customers></client><client><id>client2</id><name>Job</name><clientonly>Bar</clientonly><customers><customer><id>customer3</id><name>Yet Another Customer</name></customer></customers></client><client><id>client3</id><name>Joe</name><clientonly>Baz</clientonly></client></clients><id>root1</id><name>I'm Root</name><rootonly>Root only</rootonly></xml>"
        XCTAssertEqual(xml.description, output)
    }
    // swiftlint:enable line_length

    func testFooBarBaz() {
        let foo = "bar"
        let bar = "foo"
        let baz = 3
        let node = XMLNode(name: "FooBar", children: ["Foo": foo, "Bar": bar, "Baz": baz])
        XCTAssertEqual(node.description, "<FooBar><Foo>bar</Foo><Bar>foo</Bar><Baz>3</Baz></FooBar>")
    }

    func testXMLNodeValueSearch() throws {
        let children: XMLDictionary = [
            "foo": 1,
            "bar": 25.99,
            "baz": "Lorem Ipsum",
            "qux": true
        ]
        let xml = XMLNode(name: "xml", children: children)

        XCTAssertEqual(try xml.node(named: "foo", traversal: .breadthFirst).getValue(), 1)
        XCTAssertEqual(try xml.node(named: "bar", traversal: .breadthFirst).getValue(), 25.99)
        XCTAssertEqual(try xml.node(named: "baz", traversal: .breadthFirst).getValue(), "Lorem Ipsum")
        XCTAssertEqual(try xml.node(named: "qux", traversal: .breadthFirst).getValue(), true)

        XCTAssertEqual(try xml.getValue("foo"), 1)
        XCTAssertEqual(try xml.getValue("bar"), 25.99)
        XCTAssertEqual(try xml.getValue("baz"), "Lorem Ipsum")
        XCTAssertEqual(try xml.getValue("qux"), true)

        XCTAssertEqual(xml.getValue("foo"), Optional(1))
        XCTAssertEqual(xml.getValue("bar"), Optional(25.99))
        XCTAssertEqual(xml.getValue("baz"), Optional("Lorem Ipsum"))
        XCTAssertEqual(xml.getValue("qux"), Optional(true))

        XCTAssertEqual(xml["foo"]?.getValue(), 1)
        XCTAssertEqual(xml["bar"]?.getValue(), 25.99)
        XCTAssertEqual(xml["baz"]?.getValue(), "Lorem Ipsum")
        XCTAssertEqual(xml["qux"]?.getValue(), true)
    }

    func testXMLNodeValueSearchFailure() {
        let children: XMLDictionary = [
            "foo": 1,
            "bar": 25.99,
            "baz": "Lorem Ipsum",
            "qux": true
        ]
        let xml = XMLNode(name: "xml", children: children)

        XCTAssertThrowsError(try xml.node(named: "fooxx", traversal: .breadthFirst).getValue() as Int)
        XCTAssertThrowsError(try xml.node(named: "barxx", traversal: .breadthFirst).getValue() as Double)
        XCTAssertThrowsError(try xml.node(named: "bazxx", traversal: .breadthFirst).getValue() as String)
        XCTAssertThrowsError(try xml.node(named: "quxxx", traversal: .breadthFirst).getValue() as Bool)

        XCTAssertThrowsError(try xml.getValue("fooxx") as Int)
        XCTAssertThrowsError(try xml.getValue("barxx") as Double)
        XCTAssertThrowsError(try xml.getValue("bazxx") as String)
        XCTAssertThrowsError(try xml.getValue("quxxx") as Bool)

        XCTAssertNil(xml.getValue("fooxx") as Int?)
        XCTAssertNil(xml.getValue("barxx") as Double?)
        XCTAssertNil(xml.getValue("bazxx") as String?)
        XCTAssertNil(xml.getValue("quxxx") as Bool?)

        XCTAssertNil(xml["fooxx"]?.getValue() as Int?)
        XCTAssertNil(xml["barxx"]?.getValue() as Double?)
        XCTAssertNil(xml["bazxx"]?.getValue() as String?)
        XCTAssertNil(xml["quxxx"]?.getValue() as Bool?)
    }

    func testXMLNodeValueGetters() throws {
        let foo = XMLNode(name: "", value: 1)
        let bar = XMLNode(name: "", value: 25.99)
        let baz = XMLNode(name: "", value: "Lorem Ipsum")
        let qux = XMLNode(name: "", value: true)
        let paz = XMLNode(name: "", value: Decimal(25.99))

        XCTAssertEqual(try foo.getValue(), 1)
        XCTAssertEqual(try bar.getValue(), 25.99)
        XCTAssertEqual(try baz.getValue(), "Lorem Ipsum")
        XCTAssertEqual(try qux.getValue(), true)
        XCTAssertEqual(try paz.getValue(), Decimal(25.99))

        XCTAssertEqual(foo.getValue(), Optional(1))
        XCTAssertEqual(bar.getValue(), Optional(25.99))
        XCTAssertEqual(baz.getValue(), Optional("Lorem Ipsum"))
        XCTAssertEqual(qux.getValue(), Optional(true))
        XCTAssertEqual(paz.getValue(), Optional(Decimal(25.99)))
    }

    func testXMLNodeValueGetterFailure() {
        let foo = XMLNode(name: "")
        let bar = XMLNode(name: "")
        let baz = XMLNode(name: "")
        let qux = XMLNode(name: "")

        XCTAssertThrowsError(try foo.getValue() as Int)
        XCTAssertThrowsError(try bar.getValue() as Double)
        XCTAssertThrowsError(try baz.getValue() as String)
        XCTAssertThrowsError(try qux.getValue() as Bool)

        XCTAssertNil(foo.getValue() as Int?)
        XCTAssertNil(bar.getValue() as Double?)
        XCTAssertNil(baz.getValue() as String?)
        XCTAssertNil(qux.getValue() as Bool?)
    }

    func testThrowsNameOfNodeNotFound() throws {
        let foo = XMLNode(name: "foo")
        do {
            _ = try foo.getValue("bar") as String
        }
        catch XMLError.nodeNotFound(let name) {
            XCTAssertEqual(name, "bar")
        }
    }

    func testLosslessStringConvertible() {
        let xml = "<Node/>"
        XCTAssertEqual(XMLNode(xml)?.description, xml)
    }

    func testLosslessStringConvertibleWithValueAndAttributes() {
        let xml = """
            <Node Identifier="ID">Value</Node>
            """
        XCTAssertEqual(XMLNode(xml)?.description, xml)
    }

    func testLosslessStringConvertibleEmpty() {
        let xml = ""
        XCTAssertNil(XMLNode(xml))
    }

    func testFindValue() {
        let xml = "<Node><Child>Foo</Child></Node>"
        XCTAssertEqual(XMLNode(xml)?.findValue("Child", traversal: .firstLevel), "Foo")
    }

    func testFindValueTry() {
        let xml = "<Node><Child>Foo</Child></Node>"
        let node = XMLNode(xml) ?? XMLNode(name: "Node")
        XCTAssertNoThrow(try node.findValue("Child", traversal: .firstLevel) as String)
    }

    func testXMLNodeInjection() {
        let xml = "<Node><Parent><Child>Foo</Child></Parent></Node>"
        let node = XMLNode(xml)
        let parent = node?.nodes(named: "Parent", traversal: .breadthFirst).first
        parent?.children.append(XMLNode(name: "Child", value: "Bar"))
        XCTAssertEqual(node?.description, "<Node><Parent><Child>Foo</Child><Child>Bar</Child></Parent></Node>")
    }

    func testXMLNodeReplacement() {
        let xml = "<Node><Parent><Child>Foo</Child></Parent></Node>"
        let node = XMLNode(xml)
        let parent = node?.nodes(named: "Parent", traversal: .breadthFirst).first
        parent?.children = [XMLNode(name: "Child", value: "Bar")]
        XCTAssertEqual(node?.description, "<Node><Parent><Child>Bar</Child></Parent></Node>")
    }

    func testXMLNodeDeletion() {
        let xml = "<Node><Parent><Child>Foo</Child></Parent></Node>"
        let node = XMLNode(xml)
        let parent = node?.nodes(named: "Parent", traversal: .breadthFirst).first
        parent?.children = []
        XCTAssertEqual(node?.description, "<Node><Parent/></Node>")
    }

}
