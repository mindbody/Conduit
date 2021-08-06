//
//  AutoPurgingURLDataCache.swift
//  
//
//  Created by Anthony Lipscomb on 8/2/21.
//

import Foundation

public struct AutoPurgingURLDataCache: URLDataCache {

    private let cache: NSCache<NSString, NSData>
    private let serialQueue = DispatchQueue(
        label: "com.mindbodyonline.Conduit.AutoPurgingDataCache-\(UUID().uuidString)"
    )

    /// Initializes an AutoPurgingURLDataCache with the desired memory capacity
    ///
    /// - Parameters:
    ///     - memoryCapacity: The desired cache capacity before data eviction. Defaults to 60MB.
    ///
    /// - Important: The system will evict data based on different constraints within the system environment.
    /// It is possible for the memory capacity to be surpassed and for the system to purge data at a later time.
    public init(memoryCapacity: Int = 1_024 * 1_024 * 60) {
        cache = NSCache()
        cache.totalCostLimit = memoryCapacity
    }

    /// Attempts to retrieve a cached data for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the data
    /// - Returns: The cached data or nil of none exists
    public func data(for request: URLRequest) -> NSData? {
        guard let identifier = cacheIdentifier(for: request) else {
            return nil
        }

        var data: NSData?
        serialQueue.sync {
            data = cache.object(forKey: identifier as NSString)
        }
        return data
    }

    /// Attempts to build a cache identifier for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the data
    /// - Returns: An identifier for the cached data
    public func cacheIdentifier(for request: URLRequest) -> String? {
        return request.url?.absoluteString
    }

    /// Attempts to cache data for a given request
    ///
    /// - Parameters:
    ///     - data: The data to be cached
    ///     - request: The original request for the data
    /// - Returns: Boolean describing if the operation was successful
    @discardableResult
    public func cache(data: NSData, for request: URLRequest) -> Bool {
        guard let identifier = cacheIdentifier(for: request) else {
            return false
        }

        let totalBytes = numberOfBytes(in: data)
        serialQueue.sync {
            cache.setObject(data, forKey: identifier as NSString, cost: totalBytes)
        }
        return true
    }

    /// Attempts to remove an data from the cache for a given request
    /// - Parameters:
    ///     - request: The original request for the
    /// - Returns: Boolean describing if the operation was successful
    @discardableResult
    public func removeData(for request: URLRequest) -> Bool {
        guard let identifier = cacheIdentifier(for: request) else {
            return false
        }

        serialQueue.sync {
            cache.removeObject(forKey: identifier as NSString)
        }
        return true
    }

    /// Purges all data from the cache
    public func purge() {
        serialQueue.sync {
            cache.removeAllObjects()
        }
    }

    private func numberOfBytes(in data: NSData) -> Int {
        return data.count
    }
}
