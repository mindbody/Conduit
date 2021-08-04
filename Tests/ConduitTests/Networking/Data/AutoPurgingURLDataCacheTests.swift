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
        let sut = AutoPurgingURLDataCache()
        guard let copy = MockResource.evilSpaceshipImage.data else {
            throw TestError.invalidTest
        }
        sut.cache(data: copy as NSData, for: mockDataRequest)
        let data = sut.data(for: mockDataRequest) as Data?
        XCTAssertTrue(copy == data)
    }

    func testGeneratesCacheIdentifiers() {
        let sut = AutoPurgingURLDataCache()
        XCTAssertNotNil(sut.cacheIdentifier(for: mockDataRequest))
    }

    func testRemovesCachedDatas() throws {
        let sut = AutoPurgingURLDataCache()
        guard let data = MockResource.evilSpaceshipImage.data else {
            throw TestError.invalidTest
        }
        sut.cache(data: data as NSData, for: mockDataRequest)
        XCTAssertNotNil(sut.data(for: mockDataRequest))
        sut.removeData(for: mockDataRequest)
        XCTAssertNil(sut.data(for: mockDataRequest))
    }

    func testRemovesAllCachedDatasWhenPurged() throws {
        let sut = AutoPurgingURLDataCache()

        let dataRequests = try (0..<10).map {
            URLRequest(url: try URL(absoluteString: "https://httpbin.org/data/jpeg?id=\($0)"))
        }

        guard let data = MockResource.evilSpaceshipImage.data else {
            throw TestError.invalidTest
        }

        for request in dataRequests {
            sut.cache(data: data as NSData, for: request)
        }

        for request in dataRequests {
            XCTAssertNotNil(sut.data(for: request))
        }

        sut.purge()

        for request in dataRequests {
            XCTAssertNil(sut.data(for: request))
        }
    }

}
