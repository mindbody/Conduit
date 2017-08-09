//
//  XMLNodeConvertible.swift
//  Conduit
//
//  Created by Eneko Alonso on 8/9/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

/// Entities conforming to this protocol can be represented or can generate an XMLNode
public protocol XMLNodeRepresentable {
    var xmlNode: XMLNode { get }
}

/// Entities conforming to this protocol can be initialized with an XMLNode
public protocol XMLNodeInitializable {
    init(xmlNode: XMLNode) throws
}

/// Entities conforming to this protocol can both be initialized with and coverted to an XMLNode
public protocol XMLNodeConvertible: XMLNodeInitializable, XMLNodeRepresentable {}
