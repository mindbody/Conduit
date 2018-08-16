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
        let request = try URLRequest(url: URL(absoluteString: "http://localhost:3333/delay/2"))
        let then = Date()
        let result = try client.begin(request: request)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.response.statusCode, 200)
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(then), 2)
    }

    func testBlockingTimeout() throws {
        let client = URLSessionClient(delegateQueue: OperationQueue())
        let request = try URLRequest(url: URL(absoluteString: "http://badlocalhost/inavlid/url"))
        XCTAssertThrowsError(try client.begin(request: request))
    }

    func testTransformsRequestsThroughRequestMiddlewarePipeline() throws {
        let originalURL = try URL(absoluteString: "http://localhost:3333/put")
        let modifiedURL = try URL(absoluteString: "http://localhost:3333/get")
        let originalHTTPHeaders = ["Accept-Language": "en-US"]
        let modifiedHTTPHeaders = ["Accept-Language": "vulcan"]

        var originalRequest = URLRequest(url: originalURL)
        originalRequest.allHTTPHeaderFields = originalHTTPHeaders

        let middleware1 = TransformingRequestMiddleware1(url: modifiedURL)
        let middleware2 = TransformingRequestMiddleware2(HTTPHeaders: modifiedHTTPHeaders)

        let client = URLSessionClient(requestMiddleware: [middleware1, middleware2])
        let processedRequestExpectation = expectation(description: "processed request")
        client.begin(request: originalRequest) { _, _, _  in
            processedRequestExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)

        guard let headers = middleware2.transformedRequest?.allHTTPHeaderFields else {
            XCTFail("Expected headers")
            return
        }
        XCTAssertEqual(middleware2.transformedRequest?.url, modifiedURL)
        XCTAssertEqual(headers, modifiedHTTPHeaders)
    }

    func testPausesAndEmptiesPipelineIfRequestMiddlewareRequiresIt() throws {
        let blockingMiddleware = BlockingRequestMiddleware()
        let client = URLSessionClient(requestMiddleware: [blockingMiddleware])

        let delayedRequest = try URLRequest(url: URL(absoluteString: "http://localhost:3333/delay/2"))
        let numDelayedRequests = 5

        var completedDelayedRequests = 0

        for _ in 0..<numDelayedRequests {
            client.begin(request: delayedRequest) { _, _, _  in
                completedDelayedRequests += 1
            }
        }

        let immediateRequest = try URLRequest(url: URL(absoluteString: "http://localhost:3333/get"))

        let requestSentExpectation = expectation(description: "request sent")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            blockingMiddleware.pipelineBehaviorOptions = .awaitsOutgoingCompletion

            client.begin(request: immediateRequest) { _, _, _  in
                XCTAssert(completedDelayedRequests == numDelayedRequests)
                requestSentExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 7)
    }

    func testCancelsRequestIfRequestMiddlewareFails() throws {
        let client = URLSessionClient(requestMiddleware: [BadRequestMiddleware()])
        let request = try URLRequest(url: URL(absoluteString: "http://localhost:3333/get"))

        let requestProcessedMiddleware = expectation(description: "request processed")
        client.begin(request: request) { _, _, error in
            XCTAssertNotNil(error)
            requestProcessedMiddleware.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testSeriallyProcessesResponseMiddleware() throws {
        let baseResponseText = "test"
        let base64EncodedResponseText = "dGVzdA=="
        let transformerMiddleware1 = TransformingResponseMiddleware { data, response, error in
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                return (nil, nil, nil)
            }
            let transformedText = text + "a"
            let transformedData = transformedText.data(using: .utf8)
            return (transformedData, response, error)
        }
        let transformerMiddleware2 = TransformingResponseMiddleware { data, response, error in
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                return (nil, nil, nil)
            }
            let transformedText = text + "b"
            let transformedData = transformedText.data(using: .utf8)
            return (transformedData, response, error)
        }
        let transformerMiddleware3 = TransformingResponseMiddleware { data, response, error in
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                return (nil, nil, nil)
            }
            let transformedText = text + "c"
            let transformedData = transformedText.data(using: .utf8)
            return (transformedData, response, error)
        }

        let request = try URLRequest(url: URL(absoluteString: "http://localhost:3333/base64/\(base64EncodedResponseText)"))
        let client = URLSessionClient(responseMiddleware: [transformerMiddleware1, transformerMiddleware2, transformerMiddleware3],
                                      delegateQueue: OperationQueue())

        let (data, _) = try client.begin(request: request)

        guard let transformedData = data, let text = String(data: transformedData, encoding: .utf8) else {
            XCTFail("Transform failed")
            return
        }
        XCTAssertEqual(text, "\(baseResponseText)abc")
    }

    func testSessionTaskProxyAllowsCancellingRequestsBeforeTransport() throws {
        let request = try URLRequest(url: URL(absoluteString: "http://localhost:3333/delay/2"))
        let client: URLSessionClient = URLSessionClient()

        let requestProcessedMiddleware = expectation(description: "request processed")
        let sessionProxy = client.begin(request: request) { _, _, error in
            XCTAssertNotNil(error)
            requestProcessedMiddleware.fulfill()
        }
        sessionProxy.cancel()

        waitForExpectations(timeout: 3)
    }

    func testSessionTaskProxyAllowsSuspendingRequestsBeforeTransport() throws {
        let request = try URLRequest(url: URL(absoluteString: "http://localhost:3333/delay/2"))
        let client: URLSessionClient = URLSessionClient()

        let dispatchExecutedExpectation = expectation(description: "passed response deadline")

        let sessionProxy = client.begin(request: request) { _, _, _ in
            XCTFail("Request should not have been executed")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dispatchExecutedExpectation.fulfill()
        }

        // Suspending a task immediately after resuming it has no effect

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            sessionProxy.suspend()
        }

        waitForExpectations(timeout: 5)
    }

    func testReportsDownloadProgressForLargerTasks() throws {
        let request = try URLRequest(url: URL(absoluteString: "http://localhost:3333/stream-bytes/1500000"))
        let client: URLSessionClient = URLSessionClient()

        var progress: Progress?
        let requestFinishedExpectation = expectation(description: "request finished")
        var sessionProxy = client.begin(request: request) { _, _, _ in
            XCTAssertNotNil(progress)
            requestFinishedExpectation.fulfill()
        }
        sessionProxy.downloadProgressHandler = { progress = $0 }

        waitForExpectations(timeout: 5)
    }

    func testReportsUploadProgressForLargerTasks() throws {
        let serializer = MultipartFormRequestSerializer()
        let client: URLSessionClient = URLSessionClient()

        guard let videoData = MockResource.sampleVideo.base64EncodedData else {
            throw TestError.invalidTest
        }

        let formPart = FormPart(name: "test-video", filename: "test-video.mov", content: .video(videoData, .mov))
        serializer.append(formPart: formPart)

        let requestBuilder = HTTPRequestBuilder(url: try URL(absoluteString: "http://localhost:3333/post"))
        requestBuilder.serializer = serializer
        requestBuilder.method = .POST
        guard let request = try? requestBuilder.build() else {
            XCTFail("Failed to build rerquest")
            return
        }

        var progress: Progress?
        let requestFinishedExpectation = expectation(description: "request finished")
        var sessionProxy = client.begin(request: request) { _, _, _ in
            XCTAssertNotNil(progress)
            requestFinishedExpectation.fulfill()
        }
        sessionProxy.uploadProgressHandler = { progress = $0 }

        waitForExpectations(timeout: 5)
    }

    func testHandlesConcurrentRequests() throws {
        let request = try URLRequest(url: URL(absoluteString: "http://localhost:3333/get"))

        let client = URLSessionClient()

        let numConcurrentRequests = 20
        var completedRequests = 0

        for _ in 0..<numConcurrentRequests {
            let requestFinishedExpectation = expectation(description: "request finished")
            DispatchQueue.global().async {
                client.begin(request: request) { _, _, _  in
                    requestFinishedExpectation.fulfill()
                    completedRequests += 1
                }
            }
        }

        waitForExpectations(timeout: 5)
        XCTAssert(completedRequests == numConcurrentRequests)
    }

    func testHTTPStatusCodes() throws {
        let client = URLSessionClient(delegateQueue: OperationQueue())
        let codes = [200, 304, 400, 403, 412, 500, 501]
        for code in codes {
            let request = try URLRequest(url: URL(absoluteString: "http://localhost:3333/status/\(code)"))
            let result = try client.begin(request: request)
            XCTAssertEqual(result.response.statusCode, code)
        }
    }

}

private class BadRequestMiddleware: RequestPipelineMiddleware {
    enum WhyAreYouUsingThisMiddlewareError: Error {
        case userError
    }

    let pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .none

    func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block) {
        completion(.error(WhyAreYouUsingThisMiddlewareError.userError))
    }
}

private class TransformingRequestMiddleware1: RequestPipelineMiddleware {
    let pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .none
    let modifiedURL: URL

    init(url: URL) {
        modifiedURL = url
    }

    func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block) {
        var mutableRequest = request
        mutableRequest.url = modifiedURL
        completion(.value(mutableRequest))
    }
}

private class TransformingRequestMiddleware2: RequestPipelineMiddleware {
    var transformedRequest: URLRequest?

    var pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .none
    let modifiedHTTPHeaders: [String: String]

    init(HTTPHeaders: [String: String]) {
        modifiedHTTPHeaders = HTTPHeaders
    }

    func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block) {
        var mutableRequest = request
        mutableRequest.allHTTPHeaderFields = modifiedHTTPHeaders
        transformedRequest = mutableRequest
        completion(.value(mutableRequest))
    }
}

private class BlockingRequestMiddleware: RequestPipelineMiddleware {
    var pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .none

    func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block) {
        completion(.value(request))
    }
}

private class TransformingResponseMiddleware: ResponsePipelineMiddleware {

    typealias Transformer = (Data?, HTTPURLResponse?, Error?) -> (data: Data?, response: HTTPURLResponse?, error: Error?)

    private let transformer: Transformer

    init(transformer: @escaping Transformer) {
        self.transformer = transformer
    }

    func prepare(request: URLRequest, response: inout HTTPURLResponse?, data: inout Data?, error: inout Error?, completion: @escaping () -> Void) {
        let (transformedData, transformedResponse, transformedError) = transformer(data, response, error)
        data = transformedData
        error = transformedError
        response = transformedResponse
        let randomTimeInterval = TimeInterval(arc4random()) / TimeInterval(UInt32.max)
        DispatchQueue.global().asyncAfter(deadline: .now() + randomTimeInterval) {
            completion()
        }
    }

}
