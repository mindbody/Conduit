//
//  URLSessionClient.swift
//  Conduit
//
//  Created by John Hammerlund on 7/22/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

public typealias SessionTaskCompletion = (Data?, HTTPURLResponse?, Error?) -> Void
public typealias SessionTaskProgressHandler = (Progress) -> Void

private typealias SessionCompletionHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

/// A type that manages a session and queues URLRequest's
public protocol URLSessionClientType {

    /// Queues a request into the session pipeline, blocking until request completes or fails
    /// - Parameters:
    ///     - request: The URLRequest to be enqueued
    /// - Returns: Tuple containing data and response
    /// - Throws: Error, if any
    func begin(request: URLRequest) throws -> (data: Data?, response: HTTPURLResponse)

    /// Queues a request into the session pipeline
    /// - Parameters:
    ///     - request: The URLRequest to be enqueued
    ///     - completion: The response handler
    @discardableResult
    func begin(request: URLRequest, completion: @escaping SessionTaskCompletion) -> SessionTaskProxyType

    /// The middleware that all incoming requests should be piped through
    var requestMiddleware: [RequestPipelineMiddleware] { get set }

    var responseMiddleware: [ResponsePipelineMiddleware] { get set }
}

private class TaskResponse {
    var data: Data?
    var response: HTTPURLResponse?
    var expectedContentLength: Int64?
    var error: Error?
}

/// Errors thrown from URLSessionClient requests
public enum URLSessionClientError: Error {
    case noResponse
    case requestTimeout
}

/// Pipes requests through provided middleware and queues them into a single NSURLSession
public struct URLSessionClient: URLSessionClientType {

    /// Shared URL session client, can be overriden
    public static var shared: URLSessionClientType = URLSessionClient(delegateQueue: OperationQueue())

    /// The middleware that all incoming requests should be piped through
    public var requestMiddleware: [RequestPipelineMiddleware]

    /// The middleware that all response payloads should be piped through
    public var responseMiddleware: [ResponsePipelineMiddleware]

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
    private let sessionDelegate = SessionDelegate()
    // swiftlint:enable weak_delegate
    private static var requestCounter: Int64 = 0

    /// Creates a new URLSessionClient with provided middleware and NSURLSession parameters
    /// - Parameters:
    ///     - middleware: The middleware that all incoming requests should be piped through
    ///     - sessionConfiguration: The NSURLSessionConfiguration used to construct the underlying NSURLSession.
    ///                             Defaults to NSURLSessionConfiguration.defaultSessionConfiguration()
    ///     - delegateQueue: The NSOperationQueue in which completion handlers should execute
    public init(requestMiddleware: [RequestPipelineMiddleware] = [],
                responseMiddleware: [ResponsePipelineMiddleware] = [],
                sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                delegateQueue: OperationQueue = OperationQueue.main) {
        self.requestMiddleware = requestMiddleware
        self.responseMiddleware = responseMiddleware
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
    public func begin(request: URLRequest) throws -> (data: Data?, response: HTTPURLResponse) {
        var result: (data: Data?, response: HTTPURLResponse?, error: Error?) = (nil, nil, nil)
        let semaphore = DispatchSemaphore(value: 0)
        begin(request: request) { data, response, error in
            result = (data, response, error)
            semaphore.signal()
        }
        let timeout = urlSession.configuration.timeoutIntervalForRequest
        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            throw URLSessionClientError.requestTimeout
        }
        if let error = result.error {
            throw error
        }
        guard let response = result.response else {
            throw URLSessionClientError.noResponse
        }
        return (data: result.data, response: response)
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

            logger.verbose("Scanning middlware options ⌛︎")

            for middleware in self.requestMiddleware {
                if middleware.pipelineBehaviorOptions.contains(.awaitsOutgoingCompletion) {
                    logger.verbose("Paused session queue ⏸")
                    _ = self.activeTaskQueueDispatchGroup.wait(timeout: DispatchTime.distantFuture)
                    logger.verbose("Resumed session queue ▶️")
                }
            }

            logger.verbose("Finished scanning middleware options ✓")

            // Next, allow each middleware component to have its way with the original URLRequest
            // This is done synchronously on the serial queue since the pipeline itself shouldn't allow for concurrency

            logger.verbose("Processing request through middleware pipeline ⌛︎")

            let middlewareProcessingResult = self.synchronouslyPrepareForTransport(request: request)

            let modifiedRequest: URLRequest

            switch middlewareProcessingResult {
            case .error(let error):
                var response: HTTPURLResponse?
                var data: Data?
                var error: Error? = error
                self.synchronouslyPrepare(request: request, response: &response, data: &data, error: &error)
                self.urlSession.delegateQueue.addOperation {
                    completion(data, response, error)
                }
                return
            case .value(let request):
                modifiedRequest = request
            }

            logger.verbose("Finished processing request through middleware pipeline ✓")

            // Finally, send the request
            // Once tasks are created, the operation moves to the connection queue,
            // so even though the pipeline is serial, requests run in parallel
            let task = self.dataTaskWith(request: modifiedRequest) { data, response, error in
                var data = data
                var response = response
                var error = error
                self.serialQueue.async {
                    self.synchronouslyPrepare(request: request, response: &response, data: &data, error: &error)
                    self.urlSession.delegateQueue.addOperation {
                        self.log(data: data, response: response, request: request, requestID: requestID)
                        completion(data, response, error)
                    }
                }
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
        var middlwareError: Error?
        let middlewarePipelineDispatchGroup = DispatchGroup()
        var modifiedRequest = request

        for middleware in requestMiddleware {
            middlewarePipelineDispatchGroup.enter()

            middleware.prepareForTransport(request: modifiedRequest) { result in
                switch result {
                case .value(let request):
                    modifiedRequest = request
                case .error(let error):
                    logger.warn("Encountered an error within the middleware pipeline")
                    middlwareError = error
                }
                middlewarePipelineDispatchGroup.leave()
            }

            _ = middlewarePipelineDispatchGroup.wait(timeout: .distantFuture)

            if let error = middlwareError {
                return .error(error)
            }
        }

        return .value(modifiedRequest)
    }

    func synchronouslyPrepare(request: URLRequest, response: inout HTTPURLResponse?, data: inout Data?, error: inout Error?) {
        let dispatchGroup = DispatchGroup()

        for middleware in responseMiddleware {
            dispatchGroup.enter()

            middleware.prepare(request: request, response: &response, data: &data, error: &error) {
                dispatchGroup.leave()
            }

            _ = dispatchGroup.wait(timeout: .distantFuture)
        }
    }

    private func dataTaskWith(request: URLRequest, completion: @escaping SessionTaskCompletion) -> URLSessionDataTask {
        activeTaskQueueDispatchGroup.enter()

        let dataTask = urlSession.dataTask(with: request)
        sessionDelegate.registerCompletionHandler(taskIdentifier: dataTask.taskIdentifier) { data, response, error in
            // If for some reason the client isn't retained elsewhere, it will at least stay alive
            // while active tasks are running
            self.activeTaskQueueDispatchGroup.leave()
            completion(data, response, error)
        }

        return dataTask
    }

}

private class SessionDelegate: NSObject, URLSessionDataDelegate {

    var serverAuthenticationPolicies: [ServerAuthenticationPolicyType] = []

    private var taskCompletionHandlers: [Int: SessionTaskCompletion] = [:]
    private var taskDownloadProgressHandlers: [Int: SessionTaskProgressHandler] = [:]
    private var taskDownloadProgresses: [Int: Progress] = [:]
    private var taskUploadProgressHandlers: [Int: SessionTaskProgressHandler] = [:]
    private var taskUploadProgresses: [Int: Progress] = [:]
    private var taskResponses: [Int: TaskResponse] = [:]
    private let serialQueue = DispatchQueue(label: "com.mindbodyonline.Conduit.SessionDelegate-\(Date.timeIntervalSinceReferenceDate)")

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping SessionCompletionHandler) {
        for policy in serverAuthenticationPolicies {
            if policy.evaluate(authenticationChallenge: challenge) == false {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
        }
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.useCredential, challenge.proposedCredential)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }

    /// Reports upload progress
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if let progressHandler = taskUploadProgressHandlers[task.taskIdentifier] {
            let currentProgress = taskUploadProgresses[task.taskIdentifier]
            let newProgress = currentProgress ?? Progress()
            if currentProgress == nil {
                serialQueue.sync {
                    taskUploadProgresses[task.taskIdentifier] = newProgress
                }
            }
            newProgress.completedUnitCount = totalBytesSent
            newProgress.totalUnitCount = totalBytesExpectedToSend
            progressHandler(newProgress)
        }
    }

    /// Reports download progress and appends response data
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let taskResponse = taskResponseFor(taskIdentifier: dataTask.taskIdentifier)
        var responseData = taskResponse.data ?? Data()
        responseData.append(data)
        taskResponse.data = responseData
        if let expectedContentLength = taskResponse.expectedContentLength,
            let progressHandler = taskDownloadProgressHandlers[dataTask.taskIdentifier] {
            let currentProgress = taskDownloadProgresses[dataTask.taskIdentifier]
            let newProgress = currentProgress ?? Progress()
            if currentProgress == nil {
                serialQueue.sync {
                    taskDownloadProgresses[dataTask.taskIdentifier] = newProgress
                }
            }
            newProgress.completedUnitCount = Int64(responseData.count)
            newProgress.totalUnitCount = expectedContentLength
            progressHandler(newProgress)
        }
    }

    /// Prepares task response. This is always called before data is received.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let taskResponse = taskResponseFor(taskIdentifier: dataTask.taskIdentifier)
        taskResponse.response = response as? HTTPURLResponse
        taskResponse.expectedContentLength = response.expectedContentLength
        completionHandler(.allow)
    }

    /// Fires completion handler and releases upload, download, and completion handlers
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskResponse = taskResponseFor(taskIdentifier: task.taskIdentifier)
        taskResponse.error = error
        let completionHandler = taskCompletionHandlers[task.taskIdentifier]

        serialQueue.sync {
            taskCompletionHandlers[task.taskIdentifier] = nil
            taskDownloadProgressHandlers[task.taskIdentifier] = nil
            taskUploadProgressHandlers[task.taskIdentifier] = nil
            taskDownloadProgresses[task.taskIdentifier] = nil
            taskUploadProgresses[task.taskIdentifier] = nil
        }

        completionHandler?(taskResponse.data, taskResponse.response, taskResponse.error)
    }

    func registerCompletionHandler(taskIdentifier: Int, completionHandler: @escaping SessionTaskCompletion) {
        serialQueue.sync {
            self.taskCompletionHandlers[taskIdentifier] = completionHandler
        }
    }

    func registerDownloadProgressHandler(taskIdentifier: Int, progressHandler: @escaping SessionTaskProgressHandler) {
        serialQueue.sync {
            self.taskDownloadProgressHandlers[taskIdentifier] = progressHandler
        }
    }

    func registerUploadProgressHandler(taskIdentifier: Int, progressHandler: @escaping SessionTaskProgressHandler) {
        serialQueue.sync {
            self.taskUploadProgressHandlers[taskIdentifier] = progressHandler
        }
    }

    private func taskResponseFor(taskIdentifier: Int) -> TaskResponse {
        if let taskResponse = taskResponses[taskIdentifier] {
            return taskResponse
        }
        let taskResponse = TaskResponse()
        serialQueue.sync {
            taskResponses[taskIdentifier] = taskResponse
        }
        return taskResponse
    }

}
