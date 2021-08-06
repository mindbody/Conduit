//
//  DataDownloader.swift
//  Conduit
//
//  Created by Anthony Lipscomb on 8/2/21.
//  Copyright © 2021 MINDBODY. All rights reserved.
//

import Foundation

/// Represents an error that occurred within an DataDownloader
/// - invalidRequest: An invalid request was supplied, most likely with an empty URL
public enum DataDownloaderError: Error {
    case invalidRequest
}

public protocol DataDownloaderType {
    func downloadData(for request: URLRequest, completion: @escaping (DataDownloader.Response) -> Void) -> SessionTaskProxyType?
}

/// Utilizes Conduit to download and safely cache/retrieve
/// data across multiple threads
public final class DataDownloader: DataDownloaderType {

    /// Represents a network or cached data response
    public struct Response {
        /// The resulting data
        public let data: NSData?
        /// The error that occurred from transport or cache retrieval
        public let error: Error?
        /// The URL response, if a download occurred
        public let urlResponse: HTTPURLResponse?
        /// Signifies if the data was retrieved directly from the cache
        public let isFromCache: Bool

        public init(data: NSData?, error: Error?, urlResponse: HTTPURLResponse?, isFromCache: Bool) {
            self.data = data
            self.error = error
            self.urlResponse = urlResponse
            self.isFromCache = isFromCache
        }
    }

    /// A closure that fires upon data fetch success/failure
    public typealias CompletionHandler = (Response) -> Void

    private var cache: URLDataCache
    private let sessionClient: URLSessionClientType
    private var sessionProxyMap: [String: SessionTaskProxyType] = [:]
    private var completionHandlerMap: [String: [CompletionHandler]] = [:]
    private let completionQueue: OperationQueue?
    private let serialQueue = DispatchQueue(
        label: "com.mindbodyonline.Conduit.DataDownloader-\(UUID().uuidString)"
    )

    /// Initializes a new DataDownloader
    /// - Parameters:
    ///   - cache: The data cache in which to store downloaded data
    ///   - sessionClient: The URLSessionClient to be used to download data
    ///   - completionQueue: An optional operation queue for completion callback
    public init(cache: URLDataCache,
                sessionClient: URLSessionClientType = URLSessionClient(),
                completionQueue: OperationQueue? = nil) {
        self.cache = cache
        self.sessionClient = sessionClient
        self.completionQueue = completionQueue
    }

    /// Downloads data or retrieves it from the cache if previously downloaded.
    /// - Parameters:
    ///     - request: The request for the data
    /// - Returns: A concrete SessionTaskProxyType
    @discardableResult
    public func downloadData(for request: URLRequest, completion: @escaping CompletionHandler) -> SessionTaskProxyType? {
        var proxy: SessionTaskProxyType?
        let completionQueue = self.completionQueue ?? .current ?? .main

        serialQueue.sync { [weak self] in
            guard let `self` = self else {
                return
            }

            if let data = self.cache.data(for: request) {
                let response = Response(data: data, error: nil, urlResponse: nil, isFromCache: true)
                completion(response)
                return
            }

            guard let cacheIdentifier = self.cache.cacheIdentifier(for: request) else {
                let response = Response(data: nil,
                                        error: DataDownloaderError.invalidRequest,
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

            proxy = self.sessionClient.begin(request: request) { data, response, error in
                if let data = data {
                    _ = self.cache.cache(data: data as NSData, for: request)
                }

                let response = Response(data: data as NSData?, error: error, urlResponse: response, isFromCache: false)

                func execute(handler: @escaping CompletionHandler) {
                    completionQueue.addOperation {
                        handler(response)
                    }
                }

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
