//
//  XMLNodeIndex.swift
//  Conduit
//
//  Created by John Hammerlund on 12/19/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An XML node indexer for convenient subscripting
public struct XMLNodeIndex: Collection {

    public var startIndex: Int {
        return self.nodes.startIndex
    }

    public var endIndex: Int {
        return self.nodes.endIndex
    }

    public typealias Iterator = NodeIterator
    public let nodes: [XMLNode]

    public func makeIterator() -> XMLNodeIndex.NodeIterator {
        return NodeIterator(nodes: nodes)
    }

    public subscript(elementName: String) -> XMLNodeIndex {
        if let firstNode = nodes.first {
            return firstNode[elementName]
        }
        return XMLNodeIndex(nodes: [])
    }

    public subscript(position: Int) -> XMLNode {
        return nodes[position]
    }

    public func index(after index: Int) -> Int {
        return self.nodes.index(after: index)
    }

    public struct NodeIterator: IteratorProtocol {
        fileprivate var nodeStack: [XMLNode]

        fileprivate init(nodes: [XMLNode]) {
            self.nodeStack = nodes.reversed()
        }

        public mutating func next() -> XMLNode? {
            return nodeStack.popLast()
        }
    }

}
