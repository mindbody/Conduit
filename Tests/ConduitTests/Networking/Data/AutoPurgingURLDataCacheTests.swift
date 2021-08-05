//
//  AutoPurgingURLDataCacheTests.swift
//  ConduitTests
//
//  Created by Anthony Lipscomb on 8/3/21.
//  Copyright © 2021 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class AutoPurgingURLDataCacheTests: XCTestCase {

    var mockDataRequest: URLRequest {
        guard let url = URL(string: "https://httpbin.org/data/jpeg") else {
            XCTFail("Invalid url")
            preconditionFailure("Invalid url")
        }
        return URLRequest(url: url)
    }

    func testRetrievesCachedDatas() throws {
        // GIVEN an image as Data
        guard let copy = MockResource.evilSpaceshipImage.data else {
            throw TestError.invalidTest
        }

        // WHEN the image is cached with a request
        let sut = AutoPurgingURLDataCache()
        sut.cache(data: copy as NSData, for: mockDataRequest)

        // THEN the image can be retrieved with the same request
        let data = sut.data(for: mockDataRequest) as Data?
        XCTAssertTrue(copy == data)
    }

    func testGeneratesCacheIdentifiers() {
        // GIVEN a cache object
        // WHEN a cache is initialized
        let sut = AutoPurgingURLDataCache()
        // THEN a cache identifier will be generated
        XCTAssertNotNil(sut.cacheIdentifier(for: mockDataRequest))
    }

    func testRemovesCachedDatas() throws {
        // GIVEN a cache with an image
        guard let data = MockResource.evilSpaceshipImage.data else {
            throw TestError.invalidTest
        }

        let sut = AutoPurgingURLDataCache()
        sut.cache(data: data as NSData, for: mockDataRequest)

        XCTAssertNotNil(sut.data(for: mockDataRequest))

        // WHEN the image is removed
        sut.removeData(for: mockDataRequest)

        // THEN the image is no longer in the cache
        XCTAssertNil(sut.data(for: mockDataRequest))
    }

    func testRemovesAllCachedDatasWhenPurged() throws {
        // GIVEN a list of cached images
        let dataRequests = try (0..<10).map {
            URLRequest(url: try URL(absoluteString: "https://httpbin.org/data/jpeg?id=\($0)"))
        }

        guard let data = MockResource.evilSpaceshipImage.data else {
            throw TestError.invalidTest
        }

        let sut = AutoPurgingURLDataCache()
        for request in dataRequests {
            sut.cache(data: data as NSData, for: request)
        }

        for request in dataRequests {
            XCTAssertNotNil(sut.data(for: request))
        }

        // WHEN the cached is purged
        sut.purge()

        // THEN all requests for data in the cache will be nil
        for request in dataRequests {
            XCTAssertNil(sut.data(for: request))
        }
    }

    func testMultipleCachesHaveUniqueData() throws {
        // GIVEN a two caches
        guard let data = MockResource.evilSpaceshipImage.data else {
            throw TestError.invalidTest
        }

        let sutA = AutoPurgingURLDataCache()
        let sutB = AutoPurgingURLDataCache()

        // AND one has a cached image
        sutA.cache(data: data as NSData, for: mockDataRequest)

        // THEN the other should not contain the cached image
        XCTAssertNil(sutB.data(for: mockDataRequest))
    }

}
