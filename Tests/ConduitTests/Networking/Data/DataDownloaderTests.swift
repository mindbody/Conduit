//
//  DataDownloaderTests.swift
//  ConduitTests
//
//  Created by Anthony Lipscomb on 8/3/21.
//  Copyright © 2021 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

private class MonitoringURLSessionClient: URLSessionClientType {
    private let sessionClient = URLSessionClient()
    var requestMiddleware: [RequestPipelineMiddleware] = []
    var responseMiddleware: [ResponsePipelineMiddleware] = []

    var numRequestsSent: Int = 0

    func begin(request: URLRequest) throws -> (data: Data?, response: HTTPURLResponse) {
        numRequestsSent += 1
        return try sessionClient.begin(request: request)
    }

    func begin(request: URLRequest, completion: @escaping SessionTaskCompletion) -> SessionTaskProxyType {
        numRequestsSent += 1
        return sessionClient.begin(request: request, completion: completion)
    }
}

class DataDownloaderTests: XCTestCase {

    func testOnlyHitsNetworkOncePerRequest() throws {
        let monitoringSessionClient = MonitoringURLSessionClient()
        let sut = DataDownloader(cache: AutoPurgingURLDataCache(), sessionClient: monitoringSessionClient)
        let url = try URL(absoluteString: "https://httpbin.org/image/svg")
        let dataRequest = URLRequest(url: url)
        for _ in 0..<100 {
            sut.downloadData(for: dataRequest) { _ in }
        }
        XCTAssert(monitoringSessionClient.numRequestsSent == 1)
    }

    func testMarksDatasAsCachedAfterDownloaded() throws {
        let attemptedAllDataRetrievalsExpectation = expectation(description: "attempted all data retrievals")
        attemptedAllDataRetrievalsExpectation.expectedFulfillmentCount = 100

        let sut = DataDownloader(cache: AutoPurgingURLDataCache())
        let url = try URL(absoluteString: "https://httpbin.org/image/svg")
        let dataRequest = URLRequest(url: url)

        sut.downloadData(for: dataRequest) { response in
            XCTAssert(response.isFromCache == false)

            for _ in 0..<100 {
                sut.downloadData(for: dataRequest) { response in
                    XCTAssert(response.isFromCache == true)
                    attemptedAllDataRetrievalsExpectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testHandlesSimultaneousRequestsForDifferentDatas() {
        let dataURLs = (0..<10).compactMap {
            URL(string: "https://httpbin.org/image/svg?id=\($0)")
        }

        let sut = DataDownloader(cache: AutoPurgingURLDataCache())
        let fetchedAllDatasExpectation = expectation(description: "fetched all data")
        fetchedAllDatasExpectation.expectedFulfillmentCount = 10
        for url in dataURLs {
            sut.downloadData(for: URLRequest(url: url)) { response in
                XCTAssertNotNil(response.data)
                XCTAssertNil(response.error)
                XCTAssertFalse(response.isFromCache)
                XCTAssertEqual(response.urlResponse?.statusCode, 200)
                fetchedAllDatasExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5)
    }

    func testPersistsWhileOperationsAreRunning() throws {
        let dataDownloadedExpectation = expectation(description: "data downloaded")
        var sut: DataDownloader? = DataDownloader(cache: AutoPurgingURLDataCache())
        let url = try URL(absoluteString: "https://httpbin.org/image/svg")
        let dataRequest = URLRequest(url: url)

        weak var weakDataDownloader = sut
        sut?.downloadData(for: dataRequest) { _ in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                XCTAssert(weakDataDownloader == nil)
                dataDownloadedExpectation.fulfill()
            }
        }
        sut = nil
        XCTAssert(weakDataDownloader != nil)

        waitForExpectations(timeout: 5)
    }

    func testMainOperationQueue() throws {
        // GIVEN a main operation queue
        let expectedQueue = OperationQueue.main

        // AND a configured Data Downloader instance
        let dataDownloadedExpectation = expectation(description: "data downloaded")
        let sut = DataDownloader(cache: AutoPurgingURLDataCache())
        let url = try URL(absoluteString: "https://httpbin.org/image/svg")
        let dataRequest = URLRequest(url: url)

        // WHEN downloading an data
        sut.downloadData(for: dataRequest) { _ in
            // THEN the completion handler is called in the expected queue
            XCTAssertEqual(OperationQueue.current, expectedQueue)
            dataDownloadedExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCurrentOperationQueue() throws {
        // GIVEN an operation queue
        let expectedQueue = OperationQueue()

        // AND a configured Data Downloader instance
        let dataDownloadedExpectation = expectation(description: "data downloaded")
        let sut = DataDownloader(cache: AutoPurgingURLDataCache())
        let url = try URL(absoluteString: "https://httpbin.org/image/svg")
        let dataRequest = URLRequest(url: url)

        // WHEN downloading an data from our background queue
        expectedQueue.addOperation {
            sut.downloadData(for: dataRequest) { _ in
                // THEN the completion handler is called in the expected queue
                XCTAssertEqual(OperationQueue.current, expectedQueue)
                dataDownloadedExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testCustomOperationQueue() throws {
        // GIVEN a custom operation queue
        let customQueue = OperationQueue()

        // AND a configured Data Downloader instance with our custom completion queue
        let dataDownloadedExpectation = expectation(description: "data downloaded")
        let sut = DataDownloader(cache: AutoPurgingURLDataCache(), completionQueue: customQueue)
        let url = try URL(absoluteString: "https://httpbin.org/image/svg")
        let dataRequest = URLRequest(url: url)

        // WHEN downloading an data
        sut.downloadData(for: dataRequest) { _ in
            // THEN the completion handler is called in our custom queue
            XCTAssertEqual(OperationQueue.current, customQueue)
            dataDownloadedExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

}
