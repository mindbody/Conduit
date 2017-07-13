//
//  URLSessionClientTests.swift
//  ConduitTests
//
//  Created by Eneko Alonso on 5/16/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class URLSessionClientTests: XCTestCase {

    func testBlocking() throws {
        let client = URLSessionClient(delegateQueue: OperationQueue())
        guard let url = URL(string: "http://localhost:3333/delay/2") else {
            return XCTFail()
        }
        let request = URLRequest(url: url)
        let then = Date()
        let result = try client.begin(request: request)
        XCTAssertNotNil(result.data)
        XCTAssertEqual((result.response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(then), 2)
    }

    func testBlockingTimeout() {
        let client = URLSessionClient(delegateQueue: OperationQueue())
        guard let url = URL(string: "http://localhost/inavlid/url") else {
            return XCTFail()
        }
        let request = URLRequest(url: url)
        do {
            _ = try client.begin(request: request)
            XCTFail()
        }
        catch {
            // Expected to throw, pass
        }
    }

    func testTransformsRequestsThroughMiddlewarePipeline() {
        struct TestConstants {
            static let originalURL = URL(string: "http://localhost:3333/put")!
            static let modifiedURL = URL(string: "http://localhost:3333/get")!
            static let originalHTTPHeaders = ["Accept-Language": "en-US"]
            static let modifiedHTTPHeaders = ["Accept-Language": "vulcan"]
        }

        var originalRequest = URLRequest(url: TestConstants.originalURL)
        originalRequest.allHTTPHeaderFields = TestConstants.originalHTTPHeaders

        class TransformingMiddleware1: RequestPipelineMiddleware {
            let pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .none

            func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block) {
                var mutableRequest = request
                mutableRequest.url = TestConstants.modifiedURL
                completion(.value(mutableRequest))
            }
        }

        class TransformingMiddleware2: RequestPipelineMiddleware {
            var transformedRequest: URLRequest?

            var pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .none

            func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block) {
                var mutableRequest = request
                mutableRequest.allHTTPHeaderFields = TestConstants.modifiedHTTPHeaders
                self.transformedRequest = mutableRequest
                completion(.value(mutableRequest))
            }
        }

        let middleware1 = TransformingMiddleware1()
        let middleware2 = TransformingMiddleware2()

        let client = URLSessionClient(middleware: [middleware1, middleware2])
        let processedRequestExpectation = expectation(description: "processed request")
        client.begin(request: originalRequest) { _ in
            processedRequestExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)

        guard let headers = middleware2.transformedRequest?.allHTTPHeaderFields else {
            XCTFail()
            return
        }
        XCTAssert(middleware2.transformedRequest?.url == TestConstants.modifiedURL)
        XCTAssert(headers == TestConstants.modifiedHTTPHeaders)
    }

    func testPausesAndEmptiesPipelineIfMiddlewareRequiresIt() {
        class BlockingMiddleware: RequestPipelineMiddleware {
            var pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .none
            func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block) {
                completion(.value(request))
            }
        }

        let blockingMiddleware = BlockingMiddleware()
        let client = URLSessionClient(middleware: [blockingMiddleware])

        let delayedRequest = URLRequest(url: NSURL(string: "http://localhost:3333/delay/2")! as URL)
        let numDelayedRequests = 5

        var completedDelayedRequests = 0

        for _ in 0..<numDelayedRequests {
            client.begin(request: delayedRequest) {
                _ in completedDelayedRequests += 1
            }
        }

        let immediateRequest = URLRequest(url: NSURL(string: "http://localhost:3333/get")! as URL)

        let requestSentExpectation = expectation(description: "request sent")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            blockingMiddleware.pipelineBehaviorOptions = .awaitsOutgoingCompletion

            client.begin(request: immediateRequest) { _ in
                XCTAssert(completedDelayedRequests == numDelayedRequests)
                requestSentExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 7)
    }

    func testCancelsRequestIfMiddlewareFails() {
        class BadMiddleware: RequestPipelineMiddleware {
            enum WhyAreYouUsingThisMiddlewareError: Error {
                case userError
            }

            let pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .none

            func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block) {
                completion(.error(WhyAreYouUsingThisMiddlewareError.userError))
            }
        }

        let client = URLSessionClient(middleware: [BadMiddleware()])
        let request = URLRequest(url: NSURL(string: "http://localhost:3333/get")! as URL)

        let requestProcessedMiddleware = expectation(description: "request processed")
        client.begin(request: request) { (_, _, error) in
            XCTAssert(error != nil)
            requestProcessedMiddleware.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testSessionTaskProxyAllowsCancellingRequestsBeforeTransport() {
        let request = URLRequest(url: NSURL(string: "http://localhost:3333/delay/2")! as URL)
        let client: URLSessionClient = URLSessionClient()

        let requestProcessedMiddleware = expectation(description: "request processed")
        let sessionProxy = client.begin(request: request) { (_, _, error) in
            XCTAssert(error != nil)
            requestProcessedMiddleware.fulfill()
        }
        sessionProxy.cancel()

        waitForExpectations(timeout: 3)
    }

    func testSessionTaskProxyAllowsSuspendingRequestsBeforeTransport() {
        let request = URLRequest(url: NSURL(string: "http://localhost:3333/delay/2")! as URL)
        let client: URLSessionClient = URLSessionClient()

        let dispatchExecutedExpectation = expectation(description: "passed response deadline")

        let sessionProxy = client.begin(request: request) { (_, _, _) in
            XCTFail()
        }
        sessionProxy.suspend()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: NSEC_PER_SEC * 2)) {
            dispatchExecutedExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)
    }

    func testReportsDownloadProgressForLargerTasks() {
        let request = URLRequest(url: NSURL(string: "http://localhost:3333/stream-bytes/1500000")! as URL)
        let client: URLSessionClient = URLSessionClient()

        var progress: Progress?
        let requestFinishedExpectation = expectation(description: "request finished")
        var sessionProxy = client.begin(request: request) { (_, _, _) in
            XCTAssert(progress != nil)
            requestFinishedExpectation.fulfill()
        }
        sessionProxy.downloadProgressHandler = { progress = $0 }

        waitForExpectations(timeout: 5)
    }

    func testReportsUploadProgressForLargerTasks() {
        let serializer = MultipartFormRequestSerializer()
        let client: URLSessionClient = URLSessionClient()

        let videoFileURL = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "mov")!
        guard let videoData = try? Data(contentsOf: videoFileURL) else {
            XCTFail()
            return
        }

        let formPart = FormPart(name: "test-video", filename: "test-video.mov", content: .video(videoData, .mov))
        serializer.append(formPart: formPart)

        let requestBuilder = HTTPRequestBuilder(url: URL(string: "http://localhost:3333/post")!)
        requestBuilder.serializer = serializer
        requestBuilder.method = .POST
        guard let request = try? requestBuilder.build() else {
            XCTFail()
            return
        }

        var progress: Progress?
        let requestFinishedExpectation = expectation(description: "request finished")
        var sessionProxy = client.begin(request: request) { (_, _, _) in
            XCTAssert(progress != nil)
            requestFinishedExpectation.fulfill()
        }
        sessionProxy.uploadProgressHandler = { progress = $0 }

        waitForExpectations(timeout: 5)
    }

    func testHandlesConcurrentRequests() {
        let request = URLRequest(url: NSURL(string: "http://localhost:3333/get")! as URL)

        let client = URLSessionClient()

        let numConcurrentRequests = 20
        var completedRequests = 0

        for _ in 0..<numConcurrentRequests {
            let requestFinishedExpectation = expectation(description: "request finished")
            DispatchQueue.global().async {
                client.begin(request: request) { _ in
                    requestFinishedExpectation.fulfill()
                    completedRequests += 1
                }
            }
        }

        waitForExpectations(timeout: 5)
        XCTAssert(completedRequests == numConcurrentRequests)
    }

}
