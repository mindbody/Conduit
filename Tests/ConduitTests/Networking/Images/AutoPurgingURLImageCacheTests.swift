//
//  AutoPurgingURLImageCacheTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class AutoPurgingURLImageCacheTests: XCTestCase {

    var mockImageRequest: URLRequest {
        guard let url = URL(string: "https://httpbin.org/image/jpeg") else {
            XCTFail("Invalid url")
            preconditionFailure("Invalid url")
        }
        return URLRequest(url: url)
    }

    func testRetrievesCachedImages() throws {
        let sut = AutoPurgingURLImageCache()
        guard let copy = MockResource.evilSpaceshipImage.image else {
            throw TestError.invalidTest
        }
        sut.cache(image: copy, for: mockImageRequest)
        let image = sut.image(for: mockImageRequest)
        XCTAssert(image == copy)
    }

    func testGeneratesCacheIdentifiers() {
        let sut = AutoPurgingURLImageCache()
        XCTAssertNotNil(sut.cacheIdentifier(for: mockImageRequest))
    }

    func testRemovesCachedImages() throws {
        let sut = AutoPurgingURLImageCache()
        guard let image = MockResource.evilSpaceshipImage.image else {
            throw TestError.invalidTest
        }
        sut.cache(image: image, for: mockImageRequest)
        XCTAssertNotNil(sut.image(for: mockImageRequest))
        sut.removeImage(for: mockImageRequest)
        XCTAssertNil(sut.image(for: mockImageRequest))
    }

    func testRemovesAllCachedImagesWhenPurged() throws {
        let sut = AutoPurgingURLImageCache()

        let imageRequests = try (0..<10).map {
            URLRequest(url: try URL(absoluteString: "https://httpbin.org/image/jpeg?id=\($0)"))
        }

        guard let image = MockResource.evilSpaceshipImage.image else {
            throw TestError.invalidTest
        }

        for request in imageRequests {
            sut.cache(image: image, for: request)
        }

        for request in imageRequests {
            XCTAssertNotNil(sut.image(for: request))
        }

        sut.purge()

        for request in imageRequests {
            XCTAssertNil(sut.image(for: request))
        }
    }

}
