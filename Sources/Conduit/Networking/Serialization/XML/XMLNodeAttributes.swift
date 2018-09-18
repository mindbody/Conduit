//
//  XMLNodeAttributes.swift
//  Conduit
//
//  Created by Eneko Alonso on 9/17/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

/// Convenience alias for a single XML node attribute
public typealias XMLNodeAttribute = (attribute: String, value: String?)

/// Collection wrapper for XML Node attributes
/// Preserves order of attributes, while allowing for subscripting
public final class XMLNodeAttributes {
    private var attributes: [XMLNodeAttribute] = []

    /// Initialize a new collection of attributes
    ///
    /// - Parameter attributes: initial list of attributes
    public init(attributes: [XMLNodeAttribute] = []) {
        self.attributes = attributes
    }

    /// Retrieve or set attributes values by name
    ///
    /// - Parameter attribute: attribute name
    public subscript(attribute: String) -> String? {
        get {
            return attributes.first { $0.attribute == attribute }?.value
        }
        set {
            let item = (attribute: attribute, value: newValue)
            // Update existing attribute if possible, to preserve order
            if let index = attributes.firstIndex(where: { $0.attribute == attribute }) {
                attributes[index] = item
            }
            else {
                attributes.append(item)
            }
        }
    }

    /// Determine if the collection is empty
    public var isEmpty: Bool {
        return attributes.isEmpty
    }
}

// MARK: - CustomStringConvertible

extension XMLNodeAttributes: CustomStringConvertible {
    public var description: String {
        let attributeList = attributes.map { attributePair -> String in
            guard let value = attributePair.value else {
                return attributePair.attribute
            }
            return "\(attributePair.attribute)=\"\(value)\""
        }
        return attributeList.joined(separator: " ")
    }
}
