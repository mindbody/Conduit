//
//  XMLSubjects.swift
//  Conduit
//
//  Created by Eneko Alonso on 8/30/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation
import Conduit

extension XMLNodeTests {

    var xml: XMLNode {
        return XMLNode(name: "xml", children: [
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
    }

    var xmlDict: XMLDictionary {
        return [
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
    }

    var xmlWithIdentifiers: String {
        return """
            <Parent>
                <Child Identifier="Child1">Foo</Child>
                <Child Identifier="Child2">Bar</Child>
                <Child Identifier="Child3">Baz</Child>
            </Parent>
            """
    }

    var testSubjects: [XMLNode] {
        return [xml, XMLNode(name: "xml", children: xmlDict)]
    }

}
