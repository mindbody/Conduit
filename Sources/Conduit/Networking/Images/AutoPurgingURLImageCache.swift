//
//  AutoPurgingURLImageCache.swift
//  Conduit
//
//  Created by John Hammerlund on 3/8/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// A concrete URLImageCache that automatically purges objects
/// when memory constraints are met.
public final class AutoPurgingURLImageCache: URLImageCache {

    private var dataCache: URLDataCache

    /// Initializes an AutoPurgingURLImageCache with the desired memory capacity
    ///
    /// - Parameters:
    ///     - memoryCapacity: The desired cache capacity before image eviction. Defaults to 60MB.
    ///
    /// - Important: The system will evict images based on different constraints within the system environment.
    /// It is possible for the memory capacity to be surpassed and for the system to purge data at a later time.
    public init(memoryCapacity: Int = 1_024 * 1_024 * 60) {
        dataCache = AutoPurgingURLDataCache(memoryCapacity: memoryCapacity)
    }

    #if canImport(AppKit)
    /// Attempts to retrieve a cached image for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: The cached image or nil of none exists
    public func image(for request: URLRequest) -> NSImage? {
        guard let data = dataCache.data(for: request) as Data? else {
            return nil
        }
        return NSImage(data)
    }
    #elseif canImport(UIKit)
    /// Attempts to retrieve a cached image for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: The cached image or nil of none exists
    public func image(for request: URLRequest) -> UIImage? {
        guard let data = dataCache.data(for: request) as Data? else {
            return nil
        }
        return UIImage(data: data)
    }
    #endif

    /// Attempts to build a cache identifier for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: An identifier for the cached image
    public func cacheIdentifier(for request: URLRequest) -> String? {
        return request.url?.absoluteString
    }

    #if canImport(AppKit)
    /// Attempts to cache an image for a given request
    ///
    /// - Parameters:
    ///     - image: The image to be cached
    ///     - request: The original request for the image
    public func cache(image: NSImage, for request: URLRequest) {
        let data = Data(image)
        dataCache.cache(data: data, for: request)
    }
    #elseif canImport(UIKit)
    /// Attempts to cache an image for a given request
    ///
    /// - Parameters:
    ///     - image: The image to be cached
    ///     - request: The original request for the image
    public func cache(image: UIImage, for request: URLRequest) {
        if let data = image.pngData() {
            dataCache.cache(data: data as NSData, for: request)
        }
    }
    #endif

    /// Attempts to remove an image from the cache for a given request
    /// - Parameters:
    ///     - request: The original request for the image
    public func removeImage(for request: URLRequest) {
        dataCache.removeData(for: request)
    }

    /// Purges all images from the cache
    public func purge() {
        dataCache.purge()
    }
}
