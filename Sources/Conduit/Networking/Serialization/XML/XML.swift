//
//  XML.swift
//  Conduit
//
//  Created by John Hammerlund on 12/19/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Represents a single node in an XML document
public struct XMLNode: CustomStringConvertible {

    /// Not technically a PI, but it follows the same formatting rules
    static var versionInstruction: XMLNode = {
        var node = XMLNode(name: "xml")
        node.attributes = [
            "version": "1.0",
            "encoding": "utf-8"
        ]
        node.isProcessingInstruction = true
        return node
    }()

    /// The name of the element
    public var name: String
    /// The child nodes
    public var children: [XMLNode]?
    /// The element attributes
    public var attributes = [String: String]()
    /// The contained text value of the element
    public var value: String?
    /// Determines whether or not the element is a processing instruction
    public var isProcessingInstruction = false
    /// Determines whether or not the element is a leaf (no children)
    public var isLeaf: Bool {
        return children?.isEmpty ?? true
    }

    private var isEmpty: Bool {
        return isLeaf && value == nil
    }

    public init(name: String) {
        self.name = name
    }

    /// Returns the first-level child element with the given element name
    ///
    /// - Parameter elementName: The name of the child element
    public subscript(elementName: String) -> XMLNodeIndex {
        let matchingChildren = children?.filter { $0.name == elementName } ?? []
        return XMLNodeIndex(nodes: matchingChildren)
    }

    /// Generates the stringified XML
    public func xmlValue() -> String {
        let leftDelimiter = isProcessingInstruction ? "<?" : "<"
        let rightDelimiter = isProcessingInstruction ? "?>" : (isEmpty ? "/>" : ">")

        let hasAttributes = attributes.isEmpty == false
        let startTag: String

        if hasAttributes {
            let describedAttributes = attributes.map { "\($0.key)=\"\($0.value)\"" }.joined(separator: " ")
            startTag = "\(leftDelimiter)\(name) \(describedAttributes)\(rightDelimiter)"
        }
        else {
            startTag = "\(leftDelimiter)\(name)\(rightDelimiter)"
        }

        let endTag = "\(leftDelimiter)/\(name)\(rightDelimiter)"

        if isProcessingInstruction || isEmpty {
            return startTag
        }

        if let children = children, children.isEmpty == false {
            let body = children.map { $0.description }.joined()
            return "\(startTag)\(body)\(endTag)"
        }

        if let value = value {
            return "\(startTag)\(value)\(endTag)"
        }

        return startTag
    }

    public var description: String {
        return xmlValue()
    }

}

/// Represents an XML document
public struct XML: CustomStringConvertible {

    /// The root of the document
    public var root: XMLNode?
    /// A list of processing instructions at the root of the document
    public var processingInstructions: [XMLNode]

    /// Produces an XML document with the provided root and processing instructions.
    ///
    /// - Parameter root: The root of the document
    /// - Parameter processingInstructions: Processing instructions at the root of the document
    public init(root: XMLNode, processingInstructions: [XMLNode] = []) {
        precondition(!processingInstructions.contains { !$0.isProcessingInstruction })
        self.root = root
        self.processingInstructions = processingInstructions
    }

    /// Attempts to produce an XML document with the provided XML string
    ///
    /// - Parameter xmlString: The XML to deserialize
    public init?(xmlString: String) {
        /// Internally, we hand deserialization off to a parser class
        let parser = XML.Parser(xmlString: xmlString)
        if let xml = parser?.parse() {
            self = xml
        }
        else {
            return nil
        }
    }

    /// Generates the stringified XML
    public func xmlValue() -> String {
        var nodes = [XMLNode.versionInstruction]
        nodes.append(contentsOf: processingInstructions)
        if let root = root {
            nodes.append(root)
        }
        return nodes.map { $0.description }.joined()
    }

    public var description: String {
        return xmlValue()
    }

}

extension XML {
    fileprivate class Parser: NSObject, XMLParserDelegate {

        private let xmlParser: XMLParser
        private var workingTree = [XMLNode]()
        private var activeNode: XMLNode?
        private var root: XMLNode?

        init?(xmlString: String) {
            guard let data = xmlString.data(using: .utf8) else {
                return nil
            }
            xmlParser = XMLParser(data: data)
            super.init()
            xmlParser.delegate = self
        }

        func parse() -> XML? {
            if xmlParser.parse(),
                let root = root {
                return XML(root: root)
            }
            return nil
        }

        fileprivate func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            var node = XMLNode(name: elementName)
            node.attributes = attributeDict
            if let parentNode = workingTree.popLast() {
                workingTree.append(parentNode)
            }
            workingTree.append(node)
        }

        fileprivate func parser(_ parser: XMLParser, foundCharacters string: String) {
            var activeNode = workingTree.popLast()
            activeNode?.value = activeNode?.value?.appending(string) ?? string
            if let activeNode = activeNode {
                workingTree.append(activeNode)
            }
        }

        fileprivate func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                                qualifiedName qName: String?) {
            let finishedNode = workingTree.popLast()
            let parentNode = workingTree.popLast()
            if var parentNode = parentNode {
                if let finishedNode = finishedNode {
                    var children = parentNode.children ?? []
                    children.append(finishedNode)
                    parentNode.children = children
                }
                workingTree.append(parentNode)
            }
            else {
                root = finishedNode
            }
        }

    }
}
