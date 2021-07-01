//
//  ImageDownloader.swift
//  Conduit
//
//  Created by John Hammerlund on 3/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Represents an error that occured within an ImageDownloader
/// - invalidRequest: An invalid request was supplied, most likely with an empty URL
public enum ImageDownloaderError: Error {
    case invalidRequest
}

public protocol ImageDownloaderType {
    func downloadImage(for request: URLRequest, completion: @escaping (ImageDownloader.Response) -> Void) -> SessionTaskProxyType?
}

/// Utilizes Conduit to download and safely cache/retrieve
/// images across multiple threads
public final class ImageDownloader: ImageDownloaderType {

    /// Represents a network or cached image response
    public struct Response {
        #if canImport(AppKit)
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

        #if canImport(AppKit)
        public init(image: NSImage?, error: Error?, urlResponse: HTTPURLResponse?, isFromCache: Bool) {
            self.image = image
            self.error = error
            self.urlResponse = urlResponse
            self.isFromCache = isFromCache
        }
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        public init(image: UIImage?, error: Error?, urlResponse: HTTPURLResponse?, isFromCache: Bool) {
            self.image = image
            self.error = error
            self.urlResponse = urlResponse
            self.isFromCache = isFromCache
        }
        #endif
    }

    /// A closure that fires upon image fetch success/failure
    public typealias CompletionHandler = (Response) -> Void

    private var cache: URLImageCache
    private let sessionClient: URLSessionClientType
    private var sessionProxyMap: [String: SessionTaskProxyType] = [:]
    private var completionHandlerMap: [String: [CompletionHandler]] = [:]
    private let completionQueue: OperationQueue?
    private let serialQueue = DispatchQueue(
        label: "com.mindbodyonline.Conduit.ImageDownloader-\(UUID().uuidString)"
    )

    /// Initializes a new ImageDownloader
    /// - Parameters:
    ///   - cache: The image cache in which to store downloaded images
    ///   - sessionClient: The URLSessionClient to be used to download images
    ///   - completionQueue: An optional operation queue for completion callback
    public init(cache: URLImageCache,
                sessionClient: URLSessionClientType = URLSessionClient(),
                completionQueue: OperationQueue? = nil) {
        self.cache = cache
        self.sessionClient = sessionClient
        self.completionQueue = completionQueue
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
            let strongSelf = self
            proxy = self.sessionClient.begin(request: request) { data, response, error in
                var image: Image?
                if let data = data {
                    image = Image(data: data)
                }

                if let image = image {
                    strongSelf.cache.cache(image: image, for: request)
                }

                let response = Response(image: image, error: error, urlResponse: response, isFromCache: false)
                let queue = strongSelf.completionQueue ?? .current ?? .main

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
