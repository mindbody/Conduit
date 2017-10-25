//
//  ImageDownloaderTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

private class MonitoringURLSessionClient: URLSessionClientType {
    private let sessionClient = URLSessionClient()
    var middleware: [RequestPipelineMiddleware] = []

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

class ImageDownloaderTests: XCTestCase {

    func testOnlyHitsNetworkOncePerRequest() throws {
        let monitoringSessionClient = MonitoringURLSessionClient()
        let sut = ImageDownloader(cache: AutoPurgingURLImageCache(), sessionClient: monitoringSessionClient)
        let url = try URL(absoluteString: "http://localhost:3333/image/jpeg")
        let imageRequest = URLRequest(url: url)
        for _ in 0..<100 {
            sut.downloadImage(for: imageRequest) { _ in }
        }
        XCTAssert(monitoringSessionClient.numRequestsSent == 1)
    }

    func testMarksImagesAsCachedAfterDownloaded() throws {
        let attemptedAllImageRetrievalsExpectation = expectation(description: "attempted all image retrievals")

        let sut = ImageDownloader(cache: AutoPurgingURLImageCache())
        let url = try URL(absoluteString: "http://localhost:3333/image/jpeg")
        let imageRequest = URLRequest(url: url)

        sut.downloadImage(for: imageRequest) { response in
            XCTAssert(response.isFromCache == false)

            let dispatchGroup = DispatchGroup()

            for _ in 0..<100 {
                dispatchGroup.enter()
                DispatchQueue.global().async {
                    sut.downloadImage(for: imageRequest) { response in
                        XCTAssert(response.isFromCache == true)
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.notify(queue: DispatchQueue.main) {
                attemptedAllImageRetrievalsExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testHandlesSimultaneousRequestsForDifferentImages() {
        let imageURLs = (0..<10).flatMap {
            URL(string: "http://localhost:3333/image/jpeg?id=\($0)")
        }

        let sut = ImageDownloader(cache: AutoPurgingURLImageCache())
        let fetchedAllImagesExpectation = expectation(description: "fetched all images")
        let dispatchGroup = DispatchGroup()
        for url in imageURLs {
            dispatchGroup.enter()
            sut.downloadImage(for: URLRequest(url: url)) { response in
                XCTAssertNotNil(response.image)
                XCTAssertNil(response.error)
                XCTAssertFalse(response.isFromCache)
                XCTAssertEqual(response.urlResponse?.statusCode, 200)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            fetchedAllImagesExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testPersistsWhileOperationsAreRunning() throws {
        let imageDownloadedExpectation = expectation(description: "image downloaded")
        var sut: ImageDownloader? = ImageDownloader(cache: AutoPurgingURLImageCache())
        let url = try URL(absoluteString: "http://localhost:3333/image/jpeg")
        let imageRequest = URLRequest(url: url)

        weak var weakImageDownloader = sut
        sut?.downloadImage(for: imageRequest) { _ in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                XCTAssert(weakImageDownloader == nil)
                imageDownloadedExpectation.fulfill()
            }
        }
        sut = nil
        XCTAssert(weakImageDownloader != nil)

        waitForExpectations(timeout: 5)
    }

}
