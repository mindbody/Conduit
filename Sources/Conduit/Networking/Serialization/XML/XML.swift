//
//  XML.swift
//  Conduit
//
//  Created by John Hammerlund on 12/19/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

public enum XMLError: Error {
    case notFound
    case invalidDataType
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
            if var activeNode = workingTree.popLast() {
                let text = activeNode.text ?? ""
                activeNode.text = text + string
                workingTree.append(activeNode)
            }
        }

        fileprivate func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                                qualifiedName qName: String?) {
            let finishedNode = workingTree.popLast()
            let parentNode = workingTree.popLast()
            if var parentNode = parentNode {
                if let finishedNode = finishedNode {
                    var children = parentNode.children
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
