//
//  XMLNode.swift
//  Conduit
//
//  Created by Eneko Alonso on 7/26/17.
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
    public var children: [XMLNode]
    /// The element attributes
    public var attributes = [String: String]()
    /// The contained text value of the element
    public var value: String?
    /// Determines whether or not the element is a processing instruction
    public var isProcessingInstruction = false
    /// Determines whether or not the element is a leaf (no children)
    public var isLeaf: Bool {
        return children.isEmpty
    }

    private var isEmpty: Bool {
        return isLeaf && value == nil
    }

    /// Construct XMLNode with optional value, attributes and children
    ///
    /// - Parameters:
    ///   - name: Name of the node
    ///   - value: String value (text node)
    ///   - attributes: Node attributes dictionary
    ///   - children: Array of child nodes
    public init(name: String, value: String? = nil, attributes: [String : String] = [:], children: [XMLNode] = []) {
        self.name = name
        self.value = value
        self.attributes = attributes
        self.children = children
    }

    /// Retrieve a list of all descendant nodes with the given name
    ///
    /// - Parameter name: Node name to retrieve
    /// - Parameter traversal: Node Traversal technique. Defaults to Breadth first
    /// - Returns: Array of descendant nodes
    public func nodes(named name: String, traversal: XMLNodeTraversal = .breadthFirst) -> [XMLNode] {
        if isLeaf {
            return []
        }
        let matches = children.filter { $0.name == name }
        let breadth = traversal == .breadthFirst ? matches : []
        let descendants = children.flatMap { $0.nodes(named: name, traversal: traversal) }
        let depth = traversal == .depthFirst ? matches : []
        return breadth + descendants + depth
    }

    /// Retrieve the first descendant node with the given name
    ///
    /// - Parameter name: Node name to retrieve
    /// - Parameter traversal: Node Traversal technique. Defaults to Breadth first
    /// - Returns: Descendant nodes
    /// - Throws: XMLError if no descendant found
    public func node(named name: String, traversal: XMLNodeTraversal = .breadthFirst) throws -> XMLNode {
        guard let node = nodes(named: name, traversal: traversal).first else {
            throw XMLError.notFound
        }
        return node
    }

    /// Returns the first-level child nodes with the given name
    ///
    /// - Parameter nodeName: The name of the child element
    public subscript(nodeName: String) -> XMLNodeIndex {
        let matchingChildren = children.filter { $0.name == nodeName }
        return XMLNodeIndex(nodes: matchingChildren)
    }

    /// Retrieve the first descendant node with the given name, converted to the given type
    ///
    /// - Parameter name: Node name to retrieve
    /// - Parameter traversal: Node Traversal technique. Defaults to Breadth first
    /// - Returns: Node value (text node) converted to given type
    /// - Throws: XMLError if no descendant found, node has no value (does not contain a text node)
    ///           or if casting to type fails
    public func get<T: LosslessStringConvertible>(_ name: String, traversal: XMLNodeTraversal = .breadthFirst) throws -> T {
        return try node(named: name, traversal: traversal).getValue() as T
    }

    /// Get node value (text node) converted to given type
    ///
    /// - Returns: Node value (text node) converted to given type
    /// - Throws: XMLError if node has no value (does not contain a text node) or if casting to type fails
    public func getValue<T: LosslessStringConvertible>() throws -> T {
        guard let value = self.value, let result = T(value) else {
            throw XMLError.invalidDataType
        }
        return result
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

        if children.isEmpty == false {
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

/// Traversal options for extracting nodes from an XMLNode tree
/// - depthFirst will 
public enum XMLNodeTraversal {
    case depthFirst
    case breadthFirst
}
