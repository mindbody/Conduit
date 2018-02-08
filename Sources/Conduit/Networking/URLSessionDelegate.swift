//
//  URLSessionDelegate.swift
//  Conduit
//
//  Created by Eneko Alonso on 11/2/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

public typealias SessionTaskProgressHandler = (Progress) -> Void
internal typealias SessionCompletionHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

internal class URLSessionDelegate: NSObject, URLSessionDataDelegate {

    var serverAuthenticationPolicies: [ServerAuthenticationPolicyType] = []

    private var taskCompletionHandlers: [Int: SessionTaskCompletion] = [:]
    private var taskDownloadProgressHandlers: [Int: SessionTaskProgressHandler] = [:]
    private var taskDownloadProgresses: [Int: Progress] = [:]
    private var taskUploadProgressHandlers: [Int: SessionTaskProgressHandler] = [:]
    private var taskUploadProgresses: [Int: Progress] = [:]
    private var taskResponses: [Int: SessionTaskResponse] = [:]
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
        var taskResponse = taskResponses[dataTask.taskIdentifier] ?? SessionTaskResponse()
        var responseData = taskResponse.data ?? Data()
        responseData.append(data)
        taskResponse.data = responseData
        serialQueue.sync {
            taskResponses[dataTask.taskIdentifier] = taskResponse
        }

        if let expectedContentLength = taskResponse.response?.expectedContentLength,
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
        var taskResponse = taskResponses[dataTask.taskIdentifier] ?? SessionTaskResponse()
        taskResponse.response = response as? HTTPURLResponse
        serialQueue.sync {
            taskResponses[dataTask.taskIdentifier] = taskResponse
        }
        completionHandler(.allow)
    }

    /// Fires completion handler and releases upload, download, and completion handlers
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var taskResponse = taskResponses[task.taskIdentifier] ?? SessionTaskResponse()
        taskResponse.error = error
        serialQueue.sync {
            taskResponses[task.taskIdentifier] = taskResponse
        }

        let completionHandler = taskCompletionHandlers[task.taskIdentifier]

        serialQueue.sync {
            taskCompletionHandlers[task.taskIdentifier] = nil
            taskDownloadProgressHandlers[task.taskIdentifier] = nil
            taskUploadProgressHandlers[task.taskIdentifier] = nil
            taskDownloadProgresses[task.taskIdentifier] = nil
            taskUploadProgresses[task.taskIdentifier] = nil
        }

        completionHandler?(taskResponse)
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

}
