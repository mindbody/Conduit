//
//  XMLNode.swift
//  Conduit
//
//  Created by Eneko Alonso on 7/26/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Convenience alias for making XMLNode from a dictionary
public typealias XMLDictionary = [String: CustomStringConvertible]

/// Represents a single node in an XML document
public struct XMLNode {

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
    /// The contained text node (value) of the element
    public var text: String?
    /// Determines whether or not the element is a processing instruction
    public var isProcessingInstruction = false
    /// Determines whether or not the element is a leaf (no children)
    public var isLeaf: Bool {
        return children.isEmpty
    }

    fileprivate var isEmpty: Bool {
        return isLeaf && text == nil
    }

    /// Construct XMLNode with optional value, attributes and children
    ///
    /// - Parameters:
    ///   - name: Name of the node
    ///   - value: String value (text node)
    ///   - attributes: Node attributes dictionary
    ///   - children: Array of child nodes
    public init(name: String, value: CustomStringConvertible? = nil, attributes: [String : String] = [:], children: [XMLNode] = []) {
        self.name = name
        self.text = value?.description
        self.attributes = attributes
        self.children = children
    }

    /// Construct XML node from a dictionary of [String: CustomStringConvertible]
    /// - Supports nesting properties any number of levels
    /// - Supports arrays of nodes with the same node name (tag)
    /// - Supports text nodes from any type that conforms to CustomStringConverible (Int, Double, etc.)
    /// - Does not support node attributes
    ///
    /// Example:
    ///
    ///     let node = XMLNode(name: "FooBar", children: ["Foo": foo, "Bar": bar])
    ///
    /// - Parameters:
    ///   - name: Name of the node
    ///   - children: Dictionary of children nodes
    public init(name: String, children: XMLDictionary) {
        self.name = name
        self.children = children.map { (key, value) in
            if let grandchild = value as? XMLDictionary {
                return XMLNode(name: key, children: grandchild)
            }
            if let grandchildren = value as? [XMLDictionary] {
                let nodes = grandchildren.flatMap { XMLNode(name: "", children: $0).children }
                return XMLNode(name: key, children: nodes)
            }
            return XMLNode(name: key, value: String(describing: value))
        }
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
        if traversal == .firstLevel {
            return matches
        }

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

    /// Returns the first child node with the given name, if any
    ///
    /// - Parameter nodeName: The name of the child element
    public subscript(name: String) -> XMLNode? {
        return children.first { $0.name == name }
    }
}

// MARK: CustomStringConvertible

extension XMLNode: CustomStringConvertible {

    /// Serialized XML string output
    public var description: String {
        let leftDelimiter = isProcessingInstruction ? "<?" : "<"
        let rightDelimiter = isProcessingInstruction ? "?>" : (isEmpty ? "/>" : ">")

        let hasAttributes = attributes.isEmpty == false
        let startTag: String

        if hasAttributes {
            let describedAttributes = attributes.map({ "\($0.key)=\"\($0.value)\"" }).joined(separator: " ")
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
            let body = children.map({ $0.description }).joined()
            return "\(startTag)\(body)\(endTag)"
        }

        if let value = text {
            return "\(startTag)\(value)\(endTag)"
        }

        return startTag
    }

}

// MARK: - LosslessStringConvertible

extension XMLNode: LosslessStringConvertible {

    /// Attempts to produce an XMLNode with the provided XML string
    ///
    /// - Parameter description: The XML string to deserialize
    public init?(_ description: String) {
        guard let node = XML(description)?.root else {
            return nil
        }
        self = node
    }

}

// MARK: - Value getters

public extension XMLNode {

    /// Retrieve the first descendant node with the given name, converted to the given type
    ///
    /// - Parameter name: Node name to retrieve
    /// - Parameter traversal: Node Traversal technique. Defaults to Breadth first
    /// - Returns: Node value (text node) converted to given type
    /// - Throws: XMLError if no descendant found, node has no value (does not contain a text node)
    ///           or if casting to type fails
    public func getValue<T: LosslessStringConvertible>(_ name: String, traversal: XMLNodeTraversal = .breadthFirst) throws -> T {
        return try node(named: name, traversal: traversal).getValue() as T
    }

    /// Retrieve the first descendant node with the given name, converted to the given type
    ///
    /// - Parameter name: Node name to retrieve
    /// - Parameter traversal: Node Traversal technique. Defaults to Breadth first
    /// - Returns: Node value (text node) converted to given type
    /// - Throws: XMLError if no descendant found, node has no value (does not contain a text node)
    ///           or if casting to type fails
    public func getValue<T: LosslessStringConvertible>(_ name: String, traversal: XMLNodeTraversal = .breadthFirst) -> T? {
        guard let node = try? node(named: name, traversal: traversal) else {
            return nil
        }
        return try? node.getValue()
    }

    /// Get node value (text node) converted to given type
    ///
    /// - Returns: Node value (text node) converted to given type
    /// - Throws: XMLError if node has no value (does not contain a text node) or if casting to type fails
    public func getValue<T: LosslessStringConvertible>() throws -> T {
        guard let result: T = self.getValue() else {
            throw XMLError.invalidDataType
        }
        return result
    }

    /// Get node valye (text node) converted to a given type
    ///
    /// - Returns: Node value (text node) converted to a given type, otherwise nil
    public func getValue<T: LosslessStringConvertible>() -> T? {
        guard let text = self.text else {
            return nil
        }
        return T(text)
    }

}

/// Traversal options for extracting nodes from an XMLNode tree
public enum XMLNodeTraversal {
    case firstLevel
    case depthFirst
    case breadthFirst
}
