//
//  Request.swift
//  ConduitTests-iOS
//
//  Created by Bart Powers on 9/26/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class FakeRequest: XCTestCase {

    override func setUp() {
        super.setUp()
        logger.level = .verbose
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() throws {
        guard let govURL = URL(string: "https://api.whitehouse.gov/v1/petitions.json?limit=3&offset=0&createdBefore=1352924535") else {
            return
        }
        let requestBuilder = HTTPRequestBuilder(url: govURL)
        requestBuilder.method = .GET
        requestBuilder.serializer = JSONRequestSerializer()
        let response = try URLSessionClient.shared.begin(request: requestBuilder.build())

        print("---REQUEST---")
        print("\(logger.lastLog?.url ?? "")")
        print("\(logger.lastLog?.requestLog.headers ?? "")")
        print("\(logger.lastLog?.requestLog.body ?? "")")
        print("---RESPONSE---")
        print("\(logger.lastLog?.url ?? "")")
        print("\(logger.lastLog?.responseLog.status ?? "")")
        print("\(logger.lastLog?.responseLog.headers ?? "")")
        print("\(logger.lastLog?.responseLog.body ?? "")")
    }

}
