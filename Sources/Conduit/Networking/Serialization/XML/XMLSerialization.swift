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

    var terminator: String {
        switch self {
        case .prettyPrinted:
            return .newline
        case .condensed:
            return ""
        }
    }

    var indentation: Int {
        switch self {
        case let .prettyPrinted(spaces):
            return spaces
        case .condensed:
            return 0
        }
    }
}

extension Array where Element: XMLNode {
    public func xmlString(format: XMLSerialization = .condensed) -> String {
        return ""
    }
}

extension XMLNode {
    public func xmlString(format: XMLSerialization = .condensed) -> String {
        let terminator = format.terminator
        let describedAttributes = attributes.map { "\($0.key)=\"\($0.value)\"" }.joined(separator: " ")
        let nameAndAttributes = describedAttributes.isEmpty ? name : "\(name) \(describedAttributes)"

        if isProcessingInstruction {
            return "<?\(nameAndAttributes)?>\(terminator)"
        }
        else if children.isEmpty == false {
            let indentation = format.indentation
            let body = children.map { $0.xmlString(format: format) }.joined().indented(spaces: indentation)
            return "<\(nameAndAttributes)>\(terminator)\(body)\(terminator)</\(name)>\(terminator)"
        }
        else if let value = text {
            return "<\(nameAndAttributes)>\(value)</\(name)>\(terminator)"
        }
        else {
            return "<\(nameAndAttributes)/>\(terminator)"
        }
    }
}

extension XML {
    public func xmlString(format: XMLSerialization = .condensed) -> String {
        return ""
    }
}

extension String {

    static let newline = "\n"

    func indented(spaces: Int) -> String {
        if spaces < 1 {
            return self
        }
        let indentation = repeatElement(" ", count: spaces).joined()
        return components(separatedBy: String.newline)
            .filter { $0.isEmpty == false }
            .map { "\(indentation)\($0)" }
            .joined(separator: String.newline)
    }
}
