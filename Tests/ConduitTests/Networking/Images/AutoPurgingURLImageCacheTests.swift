//
//  AutoPurgingURLImageCacheTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class AutoPurgingURLImageCacheTests: XCTestCase {

    var mockImageRequest: URLRequest!
#if os(OSX)
    var mockImage: NSImage!
#else
    var mockImage: UIImage!
#endif
    var sut: AutoPurgingURLImageCache!

    override func setUp() {
        super.setUp()

        guard let url = URL(string: "http://localhost:3333/image/jpeg") else {
            XCTFail()
            return
        }

        mockImageRequest = URLRequest(url: url)
#if os(OSX)
        mockImage = NSImage(contentsOfFile: Bundle(for: type(of: self))
            .path(forResource: "evil_spaceship", ofType: "png")!)!
#else
        mockImage = UIImage(contentsOfFile: Bundle(for: type(of: self))
            .path(forResource: "evil_spaceship", ofType: "png")!)!
#endif
        sut = AutoPurgingURLImageCache()
    }

    func testRetrievesCachedImages() {
        sut.cache(image: mockImage, for: mockImageRequest)
        let image = sut.image(for: mockImageRequest)
        XCTAssert(image == mockImage)
    }

    func testGeneratesCacheIdentifiers() {
        XCTAssert(sut.cacheIdentifier(for: mockImageRequest) != nil)
    }

    func testRemovesCachedImages() {
        sut.cache(image: mockImage, for: mockImageRequest)
        XCTAssert(sut.image(for: mockImageRequest) != nil)
        sut.removeImage(for: mockImageRequest)
        XCTAssert(sut.image(for: mockImageRequest) == nil)
    }

    func testRemovesAllCachedImagesWhenPurged() {
        let imageRequests = (0..<10).map {
            URLRequest(url: URL(string: "http://localhost:3333/image/jpeg?id=\($0)")!)
        }

        for request in imageRequests {
            sut.cache(image: mockImage, for: request)
        }

        sut.purge()

        for request in imageRequests {
            XCTAssert(sut.image(for: request) == nil)
        }
    }

}
