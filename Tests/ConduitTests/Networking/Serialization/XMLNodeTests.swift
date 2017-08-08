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
            XCTAssertEqual(subject["id"]?.value, "root1")
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
            XCTAssertEqual(subject.nodes(named: "id", traversal: .firstLevel).first?.value, "root1")
            XCTAssertEqual(try subject.get("name", traversal: .firstLevel), "I'm Root")
            XCTAssertEqual(try subject.get("rootonly", traversal: .firstLevel), "Root only")
            XCTAssertThrowsError(try subject.get("clientonly", traversal: .firstLevel) as String)
        }
    }

    func testXMLDepthTraversal() throws {
        for subject in testSubjects {
            XCTAssertEqual(subject.nodes(named: "id", traversal: .depthFirst).first?.value(), "customer1")
            XCTAssertEqual(try subject.get("name", traversal: .depthFirst), "Customer Awesome")
            XCTAssertEqual(try subject.get("rootonly", traversal: .depthFirst), "Root only")
            XCTAssertEqual(try subject.get("clientonly", traversal: .depthFirst), "Foo")
        }
    }

    func testXMLBreadthTraversal() throws {
        for subject in testSubjects {
            XCTAssertEqual(subject.nodes(named: "id", traversal: .breadthFirst).first?.value(), "root1")
            XCTAssertEqual(try subject.get("name", traversal: .breadthFirst), "I'm Root")
            XCTAssertEqual(try subject.get("rootonly", traversal: .breadthFirst), "Root only")
            XCTAssertEqual(try subject.get("clientonly", traversal: .breadthFirst), "Foo")
        }
    }

    // swiftlint:disable line_length
    func testXMLOutput() {
        let output = "<xml><clients><client><id>client1</id><name>Bob</name><clientonly>Foo</clientonly><customers><customer><id>customer1</id><name>Customer Awesome</name></customer><customer><id>customer2</id><name>Another Customer</name></customer></customers></client><client><id>client2</id><name>Job</name><clientonly>Bar</clientonly><customers><customer><id>customer3</id><name>Yet Another Customer</name></customer></customers></client><client><id>client3</id><name>Joe</name><clientonly>Baz</clientonly></client></clients><id>root1</id><name>I'm Root</name><rootonly>Root only</rootonly></xml>"
        XCTAssertEqual(xml.xmlValue(), output)
    }
    // swiftlint:enable line_length

    func testFooBarBaz() {
        let foo = "bar"
        let bar = "foo"
        let baz = 3
        let node = XMLNode(name: "FooBar", children: ["Foo": foo, "Bar": bar, "Baz": baz])
        XCTAssertEqual(node.xmlValue(), "<FooBar><Foo>bar</Foo><Bar>foo</Bar><Baz>3</Baz></FooBar>")
    }

    func testXMLNodeValue() throws {
        let children: XMLDictionary = [
            "foo": 1,
            "bar": 25.99,
            "baz": "Lorem Ipsum",
            "qux": true
        ]
        let xml = XMLNode(name: "xml", children: children)

        XCTAssertEqual(try xml.node(named: "foo").value(), 1)
        XCTAssertEqual(try xml.node(named: "bar").value(), 25.99)
        XCTAssertEqual(try xml.node(named: "baz").value(), "Lorem Ipsum")
        XCTAssertEqual(try xml.node(named: "qux").value(), true)
    }
}
