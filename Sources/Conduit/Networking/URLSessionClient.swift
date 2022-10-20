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

/// Errors thrown from URLSessionClient requests
public enum URLSessionClientError: Error {
    case noResponse
    case requestTimeout
    case missingURL
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
    private let serialQueue = DispatchQueue(label: "com.mindbodyonline.Conduit.URLSessionClient-\(UUID().uuidString)", attributes: [])
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
    @discardableResult
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

            self.synchronouslyWaitForMiddleware()

            // Next, allow each middleware component to have its way with the original URLRequest
            // This is done synchronously on the serial queue since the pipeline itself shouldn't allow for concurrency

            logger.verbose("Processing request through middleware pipeline ⌛︎")

            let middlewareProcessingResult = self.synchronouslyProcessRequestMiddleware(for: request)

            let modifiedRequest: URLRequest

            switch middlewareProcessingResult {
            case .error(let error):
                var taskResponse = TaskResponse()
                taskResponse.error = error
                self.synchronouslyProcessResponseMiddleware(request: request, taskResponse: &taskResponse)
                self.urlSession.delegateQueue.addOperation {
                    completion(taskResponse.data, taskResponse.response, taskResponse.error)
                }
                return
            case .value(let request):
                modifiedRequest = request
            }

            logger.verbose("Finished processing request through middleware pipeline ✓")

            // This is an edge case. In `refreshBearerTokenWithin` method of Auth class we are delibertely making the request URL
            // as nil. Since the request URL is nil, the data task is not initialized and we do not get the call back.
            // To fix this we have added a nil check. If the URL is nil, we are returning a call back with missingURL error.
            guard modifiedRequest.url != nil else {
                completion(nil, nil, URLSessionClientError.missingURL)
                return
            }

            // Finally, send the request
            // Once tasks are created, the operation moves to the connection queue,
            // so even though the pipeline is serial, requests run in parallel
            let task = self.dataTaskWith(request: modifiedRequest) { taskResponse in
                self.serialQueue.async {
                    var taskResponse = taskResponse
                    self.synchronouslyProcessResponseMiddleware(request: request, taskResponse: &taskResponse)
                    self.urlSession.delegateQueue.addOperation {
                        self.log(taskResponse: taskResponse, request: request, requestID: requestID)
                        completion(taskResponse.data, taskResponse.response, taskResponse.error)
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

    private func synchronouslyWaitForMiddleware() {
        logger.verbose("Scanning middlware options ⌛︎")
        for middleware in self.requestMiddleware {
            if middleware.pipelineBehaviorOptions.contains(.awaitsOutgoingCompletion) {
                logger.verbose("Paused session queue ⏸")
                _ = self.activeTaskQueueDispatchGroup.wait(timeout: DispatchTime.distantFuture)
                logger.verbose("Resumed session queue ▶️")
            }
        }
        logger.verbose("Finished scanning middleware options ✓")
    }

    private func synchronouslyProcessRequestMiddleware(for request: URLRequest) -> Result<URLRequest> {
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

    func synchronouslyProcessResponseMiddleware(request: URLRequest, taskResponse: inout TaskResponse) {
        let dispatchGroup = DispatchGroup()

        for middleware in responseMiddleware {
            dispatchGroup.enter()

            middleware.prepare(request: request, taskResponse: &taskResponse) {
                dispatchGroup.leave()
            }

            _ = dispatchGroup.wait(timeout: .distantFuture)
        }
    }

    private func dataTaskWith(request: URLRequest, completion: @escaping (TaskResponse) -> Void) -> URLSessionDataTask {
        activeTaskQueueDispatchGroup.enter()

        let dataTask = urlSession.dataTask(with: request)
        sessionDelegate.registerCompletionHandler(taskIdentifier: dataTask.taskIdentifier) { _, _, _ in
            // Usage of strong self: If for some reason the client isn't retained elsewhere, it will at least stay alive
            // while active tasks are running
            self.activeTaskQueueDispatchGroup.leave()
            let taskResponse = self.sessionDelegate.taskResponseFor(taskIdentifier: dataTask.taskIdentifier)
            completion(taskResponse)
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
    private let serialQueue = DispatchQueue(label: "com.mindbodyonline.Conduit.SessionDelegate-\(UUID().uuidString)")

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
        var progressHandler: SessionTaskProgressHandler?
        var uploadProgress: Progress?
        serialQueue.sync {
            progressHandler = taskUploadProgressHandlers[task.taskIdentifier]
            uploadProgress = taskUploadProgresses[task.taskIdentifier] ?? Progress()
            uploadProgress?.completedUnitCount = totalBytesSent
            uploadProgress?.totalUnitCount = totalBytesExpectedToSend
            taskUploadProgresses[task.taskIdentifier] = uploadProgress
        }
        if let progress = uploadProgress {
            progressHandler?(progress)
        }
    }

    /// Reports download progress and appends response data
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        var taskResponse = taskResponseFor(taskIdentifier: dataTask.taskIdentifier)
        var responseData = taskResponse.data ?? Data()
        responseData.append(data)
        taskResponse.data = responseData
        update(taskResponse: taskResponse, for: dataTask.taskIdentifier)

        guard let expectedContentLength = taskResponse.expectedContentLength else {
            return
        }
        var progressHandler: SessionTaskProgressHandler?
        var downloadProgress: Progress?
        serialQueue.sync {
            progressHandler = taskDownloadProgressHandlers[dataTask.taskIdentifier]
            downloadProgress = taskDownloadProgresses[dataTask.taskIdentifier] ?? Progress()
            downloadProgress?.completedUnitCount = Int64(responseData.count)
            downloadProgress?.totalUnitCount = expectedContentLength
            taskDownloadProgresses[dataTask.taskIdentifier] = downloadProgress
        }
        if let progress = downloadProgress {
            progressHandler?(progress)
        }
    }

    /// Prepares task response. This delegate method is always called before data is received.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        var taskResponse = taskResponseFor(taskIdentifier: dataTask.taskIdentifier)
        taskResponse.response = response as? HTTPURLResponse
        taskResponse.expectedContentLength = response.expectedContentLength
        update(taskResponse: taskResponse, for: dataTask.taskIdentifier)
        completionHandler(.allow)
    }

    /// Stores request metrics in task response, for later consumption.
    /// This delegate method is always called after `didReceive response`, and before `didCompleteWithError`.
    @available(iOS 10, macOS 10.12, tvOS 10, watchOS 3, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        var taskResponse = taskResponseFor(taskIdentifier: task.taskIdentifier)
        taskResponse.metrics = metrics
        update(taskResponse: taskResponse, for: task.taskIdentifier)
    }

    /// Fires completion handler and releases upload, download, and completion handlers
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var taskResponse = taskResponseFor(taskIdentifier: task.taskIdentifier)
        taskResponse.error = error
        update(taskResponse: taskResponse, for: task.taskIdentifier)

        var completionHandler: SessionTaskCompletion?

        serialQueue.sync {
            completionHandler = taskCompletionHandlers[task.taskIdentifier]
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

    func taskResponseFor(taskIdentifier: Int) -> TaskResponse {
        return serialQueue.sync {
            return taskResponses[taskIdentifier] ?? makeTaskResponseFor(taskIdentifier: taskIdentifier)
        }
    }

    func update(taskResponse: TaskResponse, for taskIdentifier: Int) {
        serialQueue.sync {
            taskResponses[taskIdentifier] = taskResponse
        }
    }

    private func makeTaskResponseFor(taskIdentifier: Int) -> TaskResponse {
        let taskResponse = TaskResponse()
        taskResponses[taskIdentifier] = taskResponse
        return taskResponse
    }

}
