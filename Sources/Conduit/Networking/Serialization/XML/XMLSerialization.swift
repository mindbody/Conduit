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
        let describedAttributes = attributes.map { "\($0.key)=\"\($0.value)\"" }.joined(separator: " ")
        let nameAndAttributes = describedAttributes.isEmpty ? name : "\(name) \(describedAttributes)"

        if isProcessingInstruction {
            return "<?\(nameAndAttributes)?>\(terminator)"
        }

        if children.isEmpty == false {
            let body = children.xmlString(spaces: spaces + increment, increment: increment, terminator: terminator)
            return "\(indentation)<\(nameAndAttributes)>\(terminator)\(body)\(indentation)</\(name)>\(terminator)"
        }

        if let value = text {
            return "\(indentation)<\(nameAndAttributes)>\(value)</\(name)>\(terminator)"
        }

        return "\(indentation)<\(nameAndAttributes)/>\(terminator)"
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
