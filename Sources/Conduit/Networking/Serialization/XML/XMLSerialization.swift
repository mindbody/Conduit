//
//  XMLNodeSerialization.swift
//  Conduit
//
//  Created by Eneko Alonso on 9/5/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

public enum XMLSerialization {
    case condensed
    case prettyPrinted(spaces: Int)
}

extension Array where Element: XMLNode {
    public func xmlString(format: XMLSerialization = .condensed) -> String {
        return ""
    }
}

extension XMLNode {
    public func xmlString(format: XMLSerialization = .condensed) -> String {
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
        else if children.isEmpty == false {
            let body = children.map {
                $0.xmlString(spaces: spaces + increment, increment: increment, terminator: terminator)
            }.joined()
            return "\(indentation)<\(nameAndAttributes)>\(terminator)\(body)\(indentation)</\(name)>\(terminator)"
        }
        else if let value = text {
            return "\(indentation)<\(nameAndAttributes)>\(value)</\(name)>\(terminator)"
        }
        else {
            return "\(indentation)<\(nameAndAttributes)/>\(terminator)"
        }
    }

}

extension XML {
    public func xmlString(format: XMLSerialization = .condensed) -> String {
        return ""
    }
}
