//
//  DebugLoggerTests.swift
//  ConduitTests-iOS
//
//  Created by Bart Powers on 9/26/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class DebugLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        logger.level = .verbose
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testlogSingleRequestResponse() throws {
        guard let govURL = URL(string: "https://api.whitehouse.gov/v1/petitions.json?limit=3&offset=0&createdBefore=1352924535") else {
            return
        }
        let requestBuilder = HTTPRequestBuilder(url: govURL)
        requestBuilder.method = .GET
        requestBuilder.serializer = JSONRequestSerializer()
        let response = try URLSessionClient.shared.begin(request: requestBuilder.build())

        print("---REQUEST---")
        print("\(logger.debugLog?[0].url ?? "")")
        print("\(logger.debugLog?[0].requestLog.headers ?? "")")
        print("\(logger.debugLog?[0].requestLog.body ?? "")")
        print("---RESPONSE---")
        print("\(logger.debugLog?[0].url ?? "")")
        print("\(logger.debugLog?[0].responseLog.status ?? "")")
        print("\(logger.debugLog?[0].responseLog.headers ?? "")")
        print("\(logger.debugLog?[0].responseLog.body ?? "")")
    }

    func testlogMultipleRequestResponse() throws {
        guard let govURL = URL(string: "https://api.whitehouse.gov/v1/petitions.json?limit=3&offset=0&createdBefore=1352924535") else {
            return
        }
        var requestBuilder = HTTPRequestBuilder(url: govURL)
        requestBuilder.method = .GET
        requestBuilder.serializer = JSONRequestSerializer()
        var response = try URLSessionClient.shared.begin(request: requestBuilder.build())

        guard let govURL2 = URL(string: "https://api.whitehouse.gov/v1/signatures.json?api_key=asY1k9uCQY7Hg8MCBaa") else {
            return
        }
        requestBuilder = HTTPRequestBuilder(url: govURL2)
        requestBuilder.method = .POST
        requestBuilder.bodyParameters =   ["metadata": [
            "responseInfo": [
                "status": 200,
                "developerMessage": "OK",
                "userMessage": "",
                "errorCode": "",
                "moreInfo": ""]
            ]
        ]
        requestBuilder.serializer = JSONRequestSerializer()
        response = try URLSessionClient.shared.begin(request: requestBuilder.build())

        print("---REQUEST1---")
        print("\(logger.debugLog?[0].url ?? "")")
        print("\(logger.debugLog?[0].requestLog.headers ?? "")")
        print("\(logger.debugLog?[0].requestLog.body ?? "")")
        print("---RESPONSE1---")
        print("\(logger.debugLog?[0].url ?? "")")
        print("\(logger.debugLog?[0].responseLog.status ?? "")")
        print("\(logger.debugLog?[0].responseLog.headers ?? "")")
        print("\(logger.debugLog?[0].responseLog.body ?? "")")

        print("---REQUEST2---")
        print("\(logger.debugLog?[1].url ?? "")")
        print("\(logger.debugLog?[1].requestLog.headers ?? "")")
        print("\(logger.debugLog?[1].requestLog.body ?? "")")
        print("---RESPONSE2---")
        print("\(logger.debugLog?[1].url ?? "")")
        print("\(logger.debugLog?[1].responseLog.status ?? "")")
        print("\(logger.debugLog?[1].responseLog.headers ?? "")")
        print("\(logger.debugLog?[1].responseLog.body ?? "")")
    }

}
