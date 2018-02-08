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
            XCTAssertEqual(subject.nodes(named: "clients").count, 1)
            XCTAssertEqual(subject.nodes(named: "client").count, 3)
            XCTAssertEqual(subject.nodes(named: "customers").count, 2)
            XCTAssertEqual(subject.nodes(named: "customer").count, 3)
            XCTAssertEqual(subject.nodes(named: "id").count, 7)
        }
    }

    func testXMLFirstLevelSearch() throws {
        for subject in testSubjects {
            XCTAssertEqual(subject.nodes(named: "id", traversal: .firstLevel).first?.getValue(), "root1")
            XCTAssertEqual(try subject.getValue("name", traversal: .firstLevel), "I'm Root")
            XCTAssertEqual(try subject.getValue("rootonly", traversal: .firstLevel), "Root only")
            XCTAssertThrowsError(try subject.getValue("clientonly", traversal: .firstLevel) as String)
        }
    }

    func testXMLDepthTraversal() throws {
        for subject in testSubjects {
            XCTAssertEqual(subject.nodes(named: "id", traversal: .depthFirst).first?.getValue(), "customer1")
            XCTAssertEqual(try subject.getValue("name", traversal: .depthFirst), "Customer Awesome")
            XCTAssertEqual(try subject.getValue("rootonly", traversal: .depthFirst), "Root only")
            XCTAssertEqual(try subject.getValue("clientonly", traversal: .depthFirst), "Foo")
        }
    }

    func testXMLBreadthTraversal() throws {
        for subject in testSubjects {
            XCTAssertEqual(subject.nodes(named: "id", traversal: .breadthFirst).first?.getValue(), "root1")
            XCTAssertEqual(try subject.getValue("name", traversal: .breadthFirst), "I'm Root")
            XCTAssertEqual(try subject.getValue("rootonly", traversal: .breadthFirst), "Root only")
            XCTAssertEqual(try subject.getValue("clientonly", traversal: .breadthFirst), "Foo")
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

        XCTAssertEqual(try xml.node(named: "foo").getValue(), 1)
        XCTAssertEqual(try xml.node(named: "bar").getValue(), 25.99)
        XCTAssertEqual(try xml.node(named: "baz").getValue(), "Lorem Ipsum")
        XCTAssertEqual(try xml.node(named: "qux").getValue(), true)

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

        XCTAssertThrowsError(try xml.node(named: "fooxx").getValue() as Int)
        XCTAssertThrowsError(try xml.node(named: "barxx").getValue() as Double)
        XCTAssertThrowsError(try xml.node(named: "bazxx").getValue() as String)
        XCTAssertThrowsError(try xml.node(named: "quxxx").getValue() as Bool)

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

        XCTAssertEqual(try foo.getValue(), 1)
        XCTAssertEqual(try bar.getValue(), 25.99)
        XCTAssertEqual(try baz.getValue(), "Lorem Ipsum")
        XCTAssertEqual(try qux.getValue(), true)

        XCTAssertEqual(foo.getValue(), Optional(1))
        XCTAssertEqual(bar.getValue(), Optional(25.99))
        XCTAssertEqual(baz.getValue(), Optional("Lorem Ipsum"))
        XCTAssertEqual(qux.getValue(), Optional(true))
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

    func testThrowsInternalError() throws {
        let foo = XMLNode(name: "foo")
        do {
            _ = try foo.getValue("bar") as String
        }
        catch ConduitError.internalFailure(let message) {
            XCTAssertTrue(message.contains("bar"))
        }
    }
}
