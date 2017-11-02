//
//  URLSessionClient.swift
//  Conduit
//
//  Created by John Hammerlund on 7/22/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

public typealias SessionTaskCompletion = (SessionTaskResponse) -> Void

/// A type that manages a session and queues URLRequest's
public protocol URLSessionClientType {

    /// Queues a request into the session pipeline, blocking until request completes or fails
    /// - Parameters:
    ///     - request: The URLRequest to be enqueued
    /// - Returns: Tuple containing data and response
    /// - Throws: ConduitError, if any
    func begin(request: URLRequest) throws -> SessionTaskResponse

    /// Queues a request into the session pipeline
    /// - Parameters:
    ///     - request: The URLRequest to be enqueued
    ///     - completion: The response handler
    @discardableResult
    func begin(request: URLRequest, completion: @escaping SessionTaskCompletion) -> SessionTaskProxyType

    /// The middleware that all incoming requests should be piped through
    var middleware: [RequestPipelineMiddleware] { get set }
}

/// Pipes requests through provided middleware and queues them into a single NSURLSession
public struct URLSessionClient: URLSessionClientType {

    /// Shared URL session client, can be overriden
    public static var shared: URLSessionClientType = URLSessionClient(delegateQueue: OperationQueue())

    /// The middleware that all incoming requests should be piped through
    public var middleware: [RequestPipelineMiddleware]

    /// The authentication policies to be evaluated against for NSURLAuthenticationChallenges against the
    /// NSURLSession. Mutating this will affect all URLSessionClient copies.
    public var serverAuthenticationPolicies: [ServerAuthenticationPolicyType] {
        get { return sessionDelegate.serverAuthenticationPolicies }
        set { sessionDelegate.serverAuthenticationPolicies = newValue }
    }

    private let urlSession: URLSession
    private let serialQueue = DispatchQueue(label: "com.mindbodyonline.Conduit.URLSessionClient-\(Date.timeIntervalSinceReferenceDate)", attributes: [])
    private let activeTaskQueueDispatchGroup = DispatchGroup()

    // swiftlint:disable weak_delegate
    private let sessionDelegate = URLSessionDelegate()
    // swiftlint:enable weak_delegate

    private static var requestCounter: Int64 = 0

    /// Creates a new URLSessionClient with provided middleware and NSURLSession parameters
    /// - Parameters:
    ///     - middleware: The middleware that all incoming requests should be piped through
    ///     - sessionConfiguration: The NSURLSessionConfiguration used to construct the underlying NSURLSession.
    ///                             Defaults to NSURLSessionConfiguration.defaultSessionConfiguration()
    ///     - delegateQueue: The NSOperationQueue in which completion handlers should execute
    public init(middleware: [RequestPipelineMiddleware] = [],
                sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                delegateQueue: OperationQueue = OperationQueue.main) {
        self.middleware = middleware
        self.urlSession = URLSession(configuration: sessionConfiguration, delegate: self.sessionDelegate,
                                     delegateQueue: delegateQueue)
    }

    /// Queues a request into the session pipeline, blocking until request completes or fails.
    /// Method will throw an error if the request times out or if there is no response.
    /// Empty data (`nil`) is considered a valid result and will not throw an exception.
    ///
    /// Note: Synchronoys blocking calls will block the current thread, preventing the result from
    ///       ever being returned. To avoid this, make sure the `delegateQueue` is different than
    ///       the one from the calling thread.
    ///
    /// - Parameters:
    ///     - request: The URLRequest to be enqueued
    /// - Returns: Tuple containing data and response
    /// - Throws: URLSessionClientError, if any
    public func begin(request: URLRequest) throws -> SessionTaskResponse {
        var result = SessionTaskResponse()
        let semaphore = DispatchSemaphore(value: 0)
        begin(request: request) { taskResponse in
            result = taskResponse
            result.request = request
            semaphore.signal()
        }
        let timeout = urlSession.configuration.timeoutIntervalForRequest
        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            throw ConduitError.internalFailure(message: "Request timed out")
        }
        guard result.error == nil else {
            throw ConduitError.requestFailure(taskResponse: result)
        }
        guard result.response != nil else {
            throw ConduitError.noResponse(request: request)
        }
        return result
    }

    /// Queues a request into the session pipeline
    /// - Parameters:
    ///     - request: The URLRequest to be enqueued
    ///     - completion: The response handler, which will execute on the session's delegateQueue
    @discardableResult
    public func begin(request: URLRequest, completion: @escaping SessionTaskCompletion) -> SessionTaskProxyType {
        let sessionTaskProxy = SessionTaskProxy()

        let requestID = OSAtomicIncrement64Barrier(&URLSessionClient.requestCounter)

        serialQueue.async {

            // First, check if the queue needs to be evicted and frozen

            logger.verbose("About to scan middlware options")

            for middleware in self.middleware {
                if middleware.pipelineBehaviorOptions.contains(.awaitsOutgoingCompletion) {
                    logger.verbose("=============== WAIT ===============")
                    logger.verbose("Pausing session queue")

                    _ = self.activeTaskQueueDispatchGroup.wait(timeout: DispatchTime.distantFuture)

                    logger.verbose("Resuming session queue")
                    logger.verbose("--------------- RESUME -------------")
                }
            }

            logger.verbose("Finshed scanning middleware options")

            // Next, allow each middleware component to have its way with the original URLRequest
            // This is done synchronously on the serial queue since the pipeline itself shouldn't allow for concurrency

            logger.verbose("About to process request through middleware pipeline")

            let middlewareProcessingResult = self.synchronouslyPrepareForTransport(request: request)

            let modifiedRequest: URLRequest

            switch middlewareProcessingResult {
            case .error(let error):
                self.urlSession.delegateQueue.addOperation {
                    completion(SessionTaskResponse(error: error))
                }
                return
            case .value(let request):
                modifiedRequest = request
            }

            logger.verbose("Finished processing request through middleware pipeline")

            // Finally, send the request
            // Once tasks are created, the operation moves to the connection queue,
            // so even though the pipeline is serial, requests run in parallel
            let task = self.dataTaskWith(request: modifiedRequest) { taskResponse in
                self.log(data: taskResponse.data, response: taskResponse.response, request: modifiedRequest, requestID: requestID)
                completion(taskResponse)
            }

            self.log(request: request, requestID: requestID)

            self.sessionDelegate.registerDownloadProgressHandler(taskIdentifier: task.taskIdentifier) { progress in
                sessionTaskProxy.downloadProgressHandler?(progress)
            }

            self.sessionDelegate.registerUploadProgressHandler(taskIdentifier: task.taskIdentifier) { progress in
                sessionTaskProxy.uploadProgressHandler?(progress)
            }

            task.resume()

            sessionTaskProxy.task = task
        }

        return sessionTaskProxy
    }

    private func synchronouslyPrepareForTransport(request: URLRequest) -> Result<URLRequest> {
        var middlwareError: ConduitError?
        let middlewarePipelineDispatchGroup = DispatchGroup()
        var modifiedRequest = request

        for middleware in self.middleware {
            middlewarePipelineDispatchGroup.enter()

            middleware.prepareForTransport(request: modifiedRequest) { result in
                switch result {
                case .value(let request):
                    modifiedRequest = request
                case .error(let error):
                    let message = "Encountered an error within the middleware pipeline: \(error.localizedDescription)"
                    logger.warn(message)
                    middlwareError = ConduitError.internalFailure(message: message)
                }
                middlewarePipelineDispatchGroup.leave()
            }

            _ = middlewarePipelineDispatchGroup.wait(timeout: DispatchTime.distantFuture)

            if let error = middlwareError {
                return .error(error)
            }
        }

        return .value(modifiedRequest)
    }

    private func dataTaskWith(request: URLRequest, completion: @escaping SessionTaskCompletion) -> URLSessionDataTask {
        activeTaskQueueDispatchGroup.enter()

        let dataTask = urlSession.dataTask(with: request)
        sessionDelegate.registerCompletionHandler(taskIdentifier: dataTask.taskIdentifier) { taskResponse in
            // If for some reason the client isn't retained elsewhere, it will at least stay alive
            // while active tasks are running
            self.activeTaskQueueDispatchGroup.leave()
            completion(taskResponse)
        }

        return dataTask
    }

}
