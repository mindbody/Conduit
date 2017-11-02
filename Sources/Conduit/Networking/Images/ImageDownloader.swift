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

#if os(OSX)
    internal typealias Image = NSImage
#elseif os(iOS) || os(tvOS) || os(watchOS)
    internal typealias Image = UIImage
#endif

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
    private var sessionProxyMap: [String: SessionTaskProxyType] = [:]
    private var completionHandlerMap: [String: [CompletionHandler]] = [:]
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
            guard let strongSelf = self else {
                return
            }

            if let image = strongSelf.cache.image(for: request) {
                let response = Response(image: image, error: nil, urlResponse: nil, isFromCache: true)
                completion(response)
                return
            }

            guard let cacheIdentifier = strongSelf.cache.cacheIdentifier(for: request) else {
                let response = Response(image: nil,
                                        error: ConduitError.internalFailure(message: "Failed to get image cache identifier."),
                                        urlResponse: nil,
                                        isFromCache: false)
                completion(response)
                return
            }

            strongSelf.register(completionHandler: completion, for: cacheIdentifier)

            if let sessionTaskProxy = strongSelf.sessionProxyMap[cacheIdentifier] {
                proxy = sessionTaskProxy
                return
            }

            // Strongly capture self within the completion handler to ensure
            // ImageDownloader is persisted long enough to respond
            proxy = strongSelf.sessionClient.begin(request: request) { taskResponse in
                var image: Image?
                if let data = taskResponse.data {
                    image = Image(data: data)
                }

                if let image = image {
                    strongSelf.cache.cache(image: image, for: request)
                }

                let response = Response(image: image, error: taskResponse.error, urlResponse: taskResponse.response, isFromCache: false)
                let queue = OperationQueue.current ?? OperationQueue.main

                func execute(handler: @escaping CompletionHandler) {
                    queue.addOperation {
                        handler(response)
                    }
                }

                // Intentional retain cycle that releases immediately after execution
                strongSelf.serialQueue.async {
                    strongSelf.sessionProxyMap[cacheIdentifier] = nil
                    strongSelf.completionHandlerMap[cacheIdentifier]?.forEach(execute)
                    strongSelf.completionHandlerMap[cacheIdentifier] = nil
                }
            }

            strongSelf.sessionProxyMap[cacheIdentifier] = proxy
        }

        return proxy
    }

    private func register(completionHandler: @escaping CompletionHandler, for cacheIdentifier: String) {
        var handlers = completionHandlerMap[cacheIdentifier] ?? []
        handlers.append(completionHandler)
        completionHandlerMap[cacheIdentifier] = handlers
    }

}
