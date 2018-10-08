//
//  XMLNodeSerialization.swift
//  Conduit
//
//  Created by Eneko Alonso on 9/5/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

/// XML Serialization format
///
/// - condensed: single-line XML output
/// - prettyPrinted: human-readable format with proper indentation
public enum XMLSerialization {
    case condensed
    case prettyPrinted(spaces: Int)
}

extension XMLNode {

    /// Serialize an XMLNode and descendants into a String
    ///
    /// - Parameter format: Serialization format (.condensed or .prettyPrinted)
    /// - Returns: Serialized String
    public func xmlString(format: XMLSerialization) -> String {
        switch format {
        case .condensed:
            return xmlString(spaces: 0, increment: 0, terminator: "")
        case let .prettyPrinted(increment):
            return xmlString(spaces: 0, increment: increment, terminator: "\n")
        }
    }

    func xmlString(spaces: Int, increment: Int, terminator: String) -> String {
        let indentation = repeatElement(" ", count: spaces).joined()

        if isProcessingInstruction {
            return "<?\(nameAndAttributes)?>\(terminator)"
        }

        if children.isEmpty == false {
            let body = children.xmlString(spaces: spaces + increment, increment: increment, terminator: terminator)
            return "\(indentation)<\(nameAndAttributes)>\(terminator)\(body)\(indentation)</\(name)>\(terminator)"
        }

        if let value = text {
            let escapedValue = escapePredefinedEntities(value)
            return "\(indentation)<\(nameAndAttributes)>\(escapedValue)</\(name)>\(terminator)"
        }

        return "\(indentation)<\(nameAndAttributes)/>\(terminator)"
    }

    var nameAndAttributes: String {
        return attributes.isEmpty ? name : "\(name) \(attributes.description)"
    }

    /**
     These Predefined Entities must be escaped in XML for correct operation.
     
     They are defined in the below documentation -
     https://www.w3.org/TR/xml/#sec-predefined-ent
     
     This defines the requirements in a much more readable manner -
     https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references#Predefined_entities_in_XML
     */

    private func escapePredefinedEntities(_ text: String) -> String {
        var validXMLText = text.replacingOccurrences(of: "&", with: "&amp;")
        validXMLText = validXMLText.replacingOccurrences(of: "'", with: "&apos;")
        validXMLText = validXMLText.replacingOccurrences(of: "\"", with: "&quot;")
        validXMLText = validXMLText.replacingOccurrences(of: "<", with: "&lt;")
        validXMLText = validXMLText.replacingOccurrences(of: ">", with: "&gt;")
        return validXMLText
    }
}

extension XML {

    /// Serialize an XML document into a String
    ///
    /// - Parameter format: Serialization format (.condensed or .prettyPrinted)
    /// - Returns: Serialized String
    public func xmlString(format: XMLSerialization) -> String {
        var nodes = [XMLNode.versionInstruction]
        nodes.append(contentsOf: processingInstructions)
        if let root = root {
            nodes.append(root)
        }
        return nodes.xmlString(format: format)
    }
}

extension Array where Element: XMLNode {

    /// Serialize a collection of XMLNode and descendants into a String
    ///
    /// - Parameter format: Serialization format (.condensed or .prettyPrinted)
    /// - Returns: Serialized String
    public func xmlString(format: XMLSerialization) -> String {
        switch format {
        case .condensed:
            return xmlString(spaces: 0, increment: 0, terminator: "")
        case let .prettyPrinted(increment):
            return xmlString(spaces: 0, increment: increment, terminator: "\n")
        }
    }

    func xmlString(spaces: Int, increment: Int, terminator: String) -> String {
        return map { $0.xmlString(spaces: spaces, increment: increment, terminator: terminator) }.joined()
    }
}
