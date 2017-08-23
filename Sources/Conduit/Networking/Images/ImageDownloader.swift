//
//  ImageDownloader.swift
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
import Foundation
import Dispatch

#if os(OSX)
    internal typealias ImageType = NSImage
#elseif os(iOS) || os(tvOS) || os(watchOS)
    internal typealias ImageType = UIImage
#else
    internal typealias ImageType = Image
#endif

/// Represents an error that occured within an ImageDownloader
/// - invalidRequest: An invalid request was supplied, most likely with an empty URL
public enum ImageDownloaderError: Error {
    case invalidRequest
}

/// Utilizes Conduit to download and safely cache/retrieve
/// images across multiple threads
public final class ImageDownloader {

    /// Represents a network or cached image response
    public struct Response {
        #if os(OSX)
        /// The resulting image
        public let image: NSImage?
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        /// The resulting image
        public let image: UIImage?
        #else
        public let image: Image?
        #endif
        /// The error that occurred from transport or cache retrieval
        public let error: Error?
        /// The URL response, if a download occurred
        public let urlResponse: HTTPURLResponse?
        /// Signifies if the image was retrieved directly from the cache
        public let isFromCache: Bool
    }

    /// A closure that fires upon image fetch success/failure
    public typealias CompletionHandler = (Response) -> Void

    private var cache: URLImageCache
    private let sessionClient: URLSessionClientType
    private var sessionProxyMap: [String : SessionTaskProxyType] = [:]
    private var completionHandlerMap: [String : [CompletionHandler]] = [:]
    private let serialQueue = DispatchQueue(
        label: "com.mindbodyonline.Conduit.ImageDownloader-\(UUID().uuidString)"
    )

    /// Initializes a new ImageDownloader
    /// - Parameters:
    ///     - cache: The image cache in which to store downloaded images
    ///     - sessionClient: The URLSessionClient to be used to download images
    public init(cache: URLImageCache, sessionClient: URLSessionClientType = URLSessionClient()) {
        self.cache = cache
        self.sessionClient = sessionClient
    }

    /// Downloads an image or retrieves it from the cache if previously downloaded.
    /// - Parameters:
    ///     - request: The request for the image
    /// - Returns: A concrete SessionTaskProxyType
    @discardableResult
    public func downloadImage(for request: URLRequest, completion: @escaping CompletionHandler) -> SessionTaskProxyType? {
        var proxy: SessionTaskProxyType?

        serialQueue.sync { [weak self] in
            guard let `self` = self else {
                return
            }

            if let image = self.cache.image(for: request) {
                let response = Response(image: image, error: nil, urlResponse: nil, isFromCache: true)
                completion(response)
                return
            }

            guard let cacheIdentifier = self.cache.cacheIdentifier(for: request) else {
                let response = Response(image: nil,
                                        error: ImageDownloaderError.invalidRequest,
                                        urlResponse: nil,
                                        isFromCache: false)
                completion(response)
                return
            }

            self.register(completionHandler: completion, for: cacheIdentifier)

            if let sessionTaskProxy = self.sessionProxyMap[cacheIdentifier] {
                proxy = sessionTaskProxy
                return
            }

            // Strongly capture self within the completion handler to ensure
            // ImageDownloader is persisted long enough to respond
            proxy = self.sessionClient.begin(request: request) { (data, response, error) in
                var image: ImageType?
                if let data = data {
                    image = ImageType(data: data)
                }

                if let image = image {
                    self.cache.cache(image: image, for: request)
                }

                let response = Response(image: image, error: error, urlResponse: response, isFromCache: false)
                let queue = OperationQueue.current ?? OperationQueue.main

                func execute(handler: @escaping CompletionHandler) {
                    queue.addOperation {
                        handler(response)
                    }
                }

                // Intentional retain cycle that releases immediately after execution
                self.serialQueue.async {
                    self.sessionProxyMap[cacheIdentifier] = nil
                    self.completionHandlerMap[cacheIdentifier]?.forEach(execute)
                    self.completionHandlerMap[cacheIdentifier] = nil
                }
            }

            self.sessionProxyMap[cacheIdentifier] = proxy
        }

        return proxy
    }

    private func register(completionHandler: @escaping CompletionHandler, for cacheIdentifier: String) {
        var handlers = completionHandlerMap[cacheIdentifier] ?? []
        handlers.append(completionHandler)
        completionHandlerMap[cacheIdentifier] = handlers
    }

}
