//
//  URLDataCache.swift
//  Conduit
//
//  Created by Anthony Lipscomb on 8/2/21.
//  Copyright © 2021 MINDBODY. All rights reserved.
//

import Foundation

/// Caches data keyed off of URLRequests
public protocol URLDataCache {

    /// Attempts to retrieve cached data for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the data
    /// - Returns: The cached data or nil of none exists
    func data(for request: URLRequest) -> NSData?

    /// Attempts to build a cache identifier for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the data
    /// - Returns: An identifier for the cached data
    func cacheIdentifier(for request: URLRequest) -> String?

    /// Attempts to cache data for a given request
    ///
    /// - Parameters:
    ///     - data: The data to be cached
    ///     - request: The original request for the data
    mutating func cache(data: NSData, for request: URLRequest) -> Bool

    /// Attempts to remove data from the cache for a given request
    /// - Parameters:
    ///     - request: The original request for the data
    mutating func removeData(for request: URLRequest) -> Bool

    /// Purges all data from the cache
    mutating func purge()

}
