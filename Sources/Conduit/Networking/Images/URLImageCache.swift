//
//  URLImageCache.swift
//  Conduit
//
//  Created by John Hammerlund on 3/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

/// Caches images keyed off of URLRequests
public protocol URLImageCache {

    #if os(OSX)
    /// Attempts to retrieve a cached image for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: The cached image or nil of none exists
    func image(for request: URLRequest) -> NSImage?
    #elseif os(iOS) || os(tvOS) || os(watchOS)
    /// Attempts to retrieve a cached image for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: The cached image or nil of none exists
    func image(for request: URLRequest) -> UIImage?
    #endif

    /// Attempts to build a cache identifier for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: An identifier for the cached image
    func cacheIdentifier(for request: URLRequest) -> String?

    #if os(OSX)
    /// Attempts to cache an image for a given request
    ///
    /// - Parameters:
    ///     - image: The image to be cached
    ///     - request: The original request for the image
    mutating func cache(image: NSImage, for request: URLRequest)
    #elseif os(iOS) || os(tvOS) || os(watchOS)
    /// Attempts to cache an image for a given request
    ///
    /// - Parameters:
    ///     - image: The image to be cached
    ///     - request: The original request for the image
    mutating func cache(image: UIImage, for request: URLRequest)
    #endif

    /// Attempts to remove an image from the cache for a given request
    /// - Parameters:
    ///     - request: The original request for the image
    mutating func removeImage(for request: URLRequest)

    /// Purges all images from the cache
    mutating func purge()

}
