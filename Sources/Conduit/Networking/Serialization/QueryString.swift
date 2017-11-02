//
//  QueryString.swift
//  Conduit
//
//  Created by Matthew Holden on 8/2/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Formatting options for non-standard query string datatypes
public struct QueryStringFormattingOptions {

    /// Defines how arrays should be formatted within a query string
    public enum ArrayFormat {
        /// param=value1&param=value2&param=value3
        case duplicatedKeys
        /// param[]=value1&param[]=value2&param[]=value3
        case bracketed
        /// param[0]=value1&param[1]=value2&param[3]=value3
        case indexed
        /// param=value1,value2,value3
        case commaSeparated
    }

    /// Defines how dictionaires should be formatted within a query string
    public enum DictionaryFormat {
        /// param.key1=value1&param.key2=value2&param.key3.key4=value3
        case dotNotated
        /// param[key1]=value1&param[key2]=value2&param[key3][key4]=value3
        case subscripted
    }

    /// Defines how plus symbols should be encoded within a query string
    public enum PlusSymbolEncodingRule {
        /// param1=some+value => param1=some+value
        case decoded
        /// param1=some+value => param1=some%20value
        case replacedWithEncodedSpace
        /// param1=some+value => param1=some%2Bvalue
        case replacedWithEncodedPlus
    }

    /// Defines how spaces should be encoded within a query string
    public enum SpaceEncodingRule {
        /// param1=some value => param1=some%20value
        case encoded
        /// param1=some value => param1=some+value
        case replacedWithDecodedPlus
    }

    /// The format in which arrays should be serialized within a query string
    public var arrayFormat: ArrayFormat = .indexed
    /// The format in which dictionaries should be serialized within a query string
    public var dictionaryFormat: DictionaryFormat = .subscripted

    /// Includes any reserved delimiter characters that should be URL-encoded
    /// By default, reserved characters listed in [RFC 3986 Section 6.2.2](https://www.ietf.org/rfc/rfc3986.txt)
    /// are not encoded. This doesn't include conflicting delimiter characters (&=#[]%) which
    /// are always encoded.
    ///
    /// - Note: Non-reserved characters, characters listed above (&=#[]%), and 
    /// characters with special encoding rules (+ ) will be ignored. If more complex encoding is required,
    /// then percent-encoding will need to be handled manually.
    public var percentEncodedReservedCharacterSet: CharacterSet?

    /// Determines whether '+' should be replaced with '%2B' or '%20'. By default,
    /// this follows Apple's behavior of not encoding plus symbols.
    ///
    /// [View Radar](http://www.openradar.me/24076063)
    public var plusSymbolEncodingRule: PlusSymbolEncodingRule = .replacedWithEncodedPlus

    /// Determines whether ' ' should be replaced with '%20' or '+'. By default,
    /// this follows Apple's behavior of encoding to '%20'.
    public var spaceEncodingRule: SpaceEncodingRule = .encoded

    public init() {}

}

internal struct QueryString {

    var parameters: Any?
    var url: URL
    var formattingOptions: QueryStringFormattingOptions

    init(parameters: Any?, url: URL, formattingOptions: QueryStringFormattingOptions = QueryStringFormattingOptions()) {
        self.parameters = parameters
        self.url = url
        self.formattingOptions = formattingOptions
    }

    func encodeURL() throws -> URL {
        guard let params = parameters else {
            return url
        }

        var queryItems = [URLQueryItem]()

        switch params {
        case let dictionary as [String: Any]:
            queryItems.append(contentsOf: queryItemsFromDictionary(dict: dictionary))
        case let number as NSNumber:
            let newPath = "\(url.absoluteString)?\(number.stringValue)"
            guard let newUrl = URL(string: newPath) else {
                throw ConduitError.serializationError(message: "Invalid url: \(newPath)")
            }
            return newUrl
        default:
            let newPath = "\(url.absoluteString)?\(params)"
            guard let newUrl = URL(string: newPath) else {
                throw ConduitError.serializationError(message: "Invalid url: \(newPath)")
            }
            return newUrl
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw ConduitError.serializationError(message: "Failed to parse url components: \(url.absoluteString)")
        }
        components.queryItems = queryItems

        /// Respect encoding rules

        if let percentEncodedQuery = components.percentEncodedQuery {
            components.percentEncodedQuery = format(percentEncodedQuery: percentEncodedQuery)
        }

        guard let finalURL = components.url else {
            throw ConduitError.serializationError(message: "Failed to compose url: \(url.absoluteString)")
        }

        return finalURL
    }

    private func format(percentEncodedQuery: String) -> String {
        /// To avoid nasty bugs, we're going to trade a tiny bit of performance for
        /// cleaner code. We'll take the original version of the encoded query and identify/
        /// replace '+' and '%20' with their own hashes for later search/replace

        let spaceIdentifier = UUID().uuidString
        let plusIdentifier = UUID().uuidString

        var searchablePercentEncodedQuery =
            percentEncodedQuery.replacingOccurrences(of: "%20", with: spaceIdentifier)
        searchablePercentEncodedQuery =
            searchablePercentEncodedQuery.replacingOccurrences(of: "+",
                                                               with: plusIdentifier)

        let plusSymbolReplacement: String
        switch formattingOptions.plusSymbolEncodingRule {
        case .decoded:
            plusSymbolReplacement = "+"
        case .replacedWithEncodedPlus:
            plusSymbolReplacement = "%2B"
        case .replacedWithEncodedSpace:
            plusSymbolReplacement = "%20"
        }

        let spaceReplacement: String
        switch formattingOptions.spaceEncodingRule {
        case .encoded:
            spaceReplacement = "%20"
        case .replacedWithDecodedPlus:
            spaceReplacement = "+"
        }

        var newPercentEncodedQuery =
            searchablePercentEncodedQuery.replacingOccurrences(of: plusIdentifier,
                                                               with: plusSymbolReplacement)
        newPercentEncodedQuery =
            newPercentEncodedQuery.replacingOccurrences(of: spaceIdentifier,
                                                        with: spaceReplacement)

        if var percentEncodedReservedCharacterSet = formattingOptions.percentEncodedReservedCharacterSet {
            // Only encode reserved characters that don't conflict with query delimiters or special encoding rules
            let reservedCharacterSet = CharacterSet(charactersIn: "!*'();:@$,/?")
            percentEncodedReservedCharacterSet = percentEncodedReservedCharacterSet.intersection(reservedCharacterSet)
            newPercentEncodedQuery = newPercentEncodedQuery
                .addingPercentEncoding(withAllowedCharacters: percentEncodedReservedCharacterSet.inverted) ?? newPercentEncodedQuery
        }

        return newPercentEncodedQuery
    }

    private func queryItemsFromDictionary(dict: [String: Any]) -> [URLQueryItem] {
        return dict.flatMap { kvp in
            queryItemsFrom(parameter: (kvp.key, kvp.value))
        }
    }

    private func queryItemsFrom(parameter: (String, Any)) -> [URLQueryItem] {
        let name = parameter.0
        var value: String?
        if let parameterValue = parameter.1 as? [Any] {
            return queryItemsFrom(arrayParameter: (name, parameterValue))
        }
        if let parameterValue = parameter.1 as? [String: Any] {
            return queryItemsFrom(dictionaryParameter: (name, parameterValue))
        }
        if let parameterValue = parameter.1 as? String {
            value = parameterValue
        }
        else if let parameterValue = parameter.1 as? NSNumber {
            value = parameterValue.stringValue
        }
        else if parameter.1 is NSNull {
            value = nil
        }
        else {
            value = "\(parameter.1)"
        }
        return [URLQueryItem(name: name, value: value)]
    }

    private func queryItemsFrom(arrayParameter parameter: (String, [Any])) -> [URLQueryItem] {
        let key = parameter.0
        let value = parameter.1
        switch formattingOptions.arrayFormat {
        case .indexed:
            return value.enumerated().flatMap { queryItemsFrom(parameter: ("\(key)[\($0)]", $1)) }
        case .bracketed:
            return value.flatMap { queryItemsFrom(parameter: ("\(key)[]", $0)) }
        case .duplicatedKeys:
            return value.flatMap { queryItemsFrom(parameter: (key, $0)) }
        case .commaSeparated:
            let queryItemValue = value.map { "\($0)" }.joined(separator: ",")
            return [URLQueryItem(name: key, value: queryItemValue)]
        }
    }

    private func queryItemsFrom(dictionaryParameter parameter: (String, [String: Any])) -> [URLQueryItem] {
        let key = parameter.0
        let value = parameter.1
        switch formattingOptions.dictionaryFormat {
        case .dotNotated:
            return value.flatMap { queryItemsFrom(parameter: ("\(key).\($0)", $1)) }
        case .subscripted:
            return value.flatMap { queryItemsFrom(parameter: ("\(key)[\($0)]", $1)) }
        }
    }

}
