//
//  AutoPurgingURLImageCache.swift
//  Conduit
//
//  Created by John Hammerlund on 3/8/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

/// A concrete URLImageCache that automatically purges objects
/// when memory constraints are met.
public final class AutoPurgingURLImageCache: URLImageCache {

    private let cache: NSCache<NSString, Image>
    private let serialQueue = DispatchQueue(
        label: "com.mindbodyonline.Conduit.AutoPurgingImageCache-\(UUID().uuidString)"
    )

    /// Initializes an AutoPurgingURLImageCache with the desired memory capacity
    ///
    /// - Parameters:
    ///     - memoryCapacity: The desired cache capacity before image eviction. Defaults to 60MB.
    ///
    /// - Important: The system will evict images based on different constraints within the system environment.
    /// It is possible for the memory capacity to be surpassed and for the system to purge data at a later time.
    public init(memoryCapacity: Int = 1_024 * 1_024 * 60) {
        cache = NSCache()
        cache.totalCostLimit = memoryCapacity
    }

    #if os(OSX)
    /// Attempts to retrieve a cached image for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: The cached image or nil of none exists
    public func image(for request: URLRequest) -> NSImage? {
    return _image(for: request)
    }
    #endif

    #if os(iOS) || os(tvOS) || os(watchOS)
    /// Attempts to retrieve a cached image for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: The cached image or nil of none exists
    public func image(for request: URLRequest) -> UIImage? {
        return _image(for: request)
    }
    #endif

    private func _image(for request: URLRequest) -> Image? {
        guard let identifier = cacheIdentifier(for: request) else {
            return nil
        }

        var image: Image?
        let cache = self.cache
        serialQueue.sync {
            image = cache.object(forKey: identifier as NSString)
        }
        return image
    }

    /// Attempts to build a cache identifier for the given request
    ///
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: An identifier for the cached image
    public func cacheIdentifier(for request: URLRequest) -> String? {
        return request.url?.absoluteString
    }

    #if os(OSX)
    /// Attempts to cache an image for a given request
    ///
    /// - Parameters:
    ///     - image: The image to be cached
    ///     - request: The original request for the image
    public func cache(image: NSImage, for request: URLRequest) {
    _cache(image: image, for: request)
    }
    #endif

    #if os(iOS) || os(tvOS) || os(watchOS)
    /// Attempts to cache an image for a given request
    ///
    /// - Parameters:
    ///     - image: The image to be cached
    ///     - request: The original request for the image
    public func cache(image: UIImage, for request: URLRequest) {
        _cache(image: image, for: request)
    }
    #endif

    private func _cache(image: Image, for request: URLRequest) {
        guard let identifier = cacheIdentifier(for: request) else {
            return
        }

        let cache = self.cache
        let totalBytes = numberOfBytes(in: image)
        serialQueue.sync {
            cache.setObject(image, forKey: identifier as NSString, cost: totalBytes)
        }
    }

    /// Attempts to remove an image from the cache for a given request
    /// - Parameters:
    ///     - request: The original request for the image
    public func removeImage(for request: URLRequest) {
        guard let identifier = cacheIdentifier(for: request) else {
            return
        }

        let cache = self.cache
        serialQueue.sync {
            cache.removeObject(forKey: identifier as NSString)
        }
    }

    /// Purges all images from the cache
    public func purge() {
        serialQueue.sync {
            cache.removeAllObjects()
        }
    }

    #if os(OSX)
    private func numberOfBytes(in image: Image) -> Int {
        return image.tiffRepresentation?.count ?? 0
    }
    #endif

    #if os(iOS) || os(tvOS) || os(watchOS)
    private func numberOfBytes(in image: Image) -> Int {
        let size = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let bytesPerPixel = 4
        let scaledImageArea = Int(size.width * size.height)
        return scaledImageArea * bytesPerPixel
    }
    #endif
    
}
