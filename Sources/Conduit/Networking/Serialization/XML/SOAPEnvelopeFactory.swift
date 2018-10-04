//
//  SOAPEnvelopeFactory.swift
//  Conduit
//
//  Created by John Hammerlund on 12/16/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Builds XML documents preformatted for SOAP transport.
/// - Note: Headers and multiple namespaces are not yet supported.
public struct SOAPEnvelopeFactory {

    /// The XML namespace for SOAP envelope elements (schema: http://schemas.xmlsoap.org/soap/envelope/)
    public var soapEnvelopeNamespace: String = "soap"
    /// The schema in which all non-prefixed elements are bound to (i.e. http://clients.mindbodyonline.com/api/0_5)
    public var rootNamespaceSchema: String?
    /// The SOAP encoding style. Defaults to empty string.
    public var encodingStyle: String = ""

    /// Produces a SOAPEnvelopeFactory
    public init() {}

    func makeSOAPEnvelope() -> XMLNode {
        let node = XMLNode(name: "\(soapEnvelopeNamespace):Envelope")
        node.attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
        node.attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
        node.attributes["xmlns:\(soapEnvelopeNamespace)"] = "http://schemas.xmlsoap.org/soap/envelope/"
        node.attributes["xmlns"] = rootNamespaceSchema
        node.attributes["\(soapEnvelopeNamespace):encodingStyle"] = encodingStyle
        return node
    }

    func makeSOAPBody(root: XMLNode) -> XMLNode {
        let node = XMLNode(name: "\(soapEnvelopeNamespace):Body")
        node.children = [root]
        return node
    }

    /// Produces an XML document with the provided root body element
    ///
    /// - Parameter soapBody: The root body element
    /// - Returns: A formatted SOAP XML document
    public func makeXML(soapBody: XMLNode) -> XML {
        let soapBody = makeSOAPBody(root: soapBody)
        let envelope = makeSOAPEnvelope()
        envelope.children = [soapBody]
        return XML(root: envelope)
    }

}
