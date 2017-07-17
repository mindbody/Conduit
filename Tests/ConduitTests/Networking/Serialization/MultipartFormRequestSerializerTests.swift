//
//  MultipartFormRequestSerializerTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

enum TestError: Error {
    case invalidTest
}

class MultipartFormRequestSerializerTests: XCTestCase {

    var request: URLRequest!
    var serializer: MultipartFormRequestSerializer!

    var image1: Image!
    var image2: Image!

    override func setUp() {
        super.setUp()

        guard let url = URL(string: "http://localhost:3333") else {
            XCTFail()
            return
        }

        guard let image1File = Bundle(for: type(of: self)).path(forResource: "celltowers", ofType: "JPG") else {
            XCTFail()
            return
        }
        guard let image2File = Bundle(for: type(of: self)).path(forResource: "evil_spaceship", ofType: "png") else {
            XCTFail()
            return
        }
        image1 = Image(contentsOfFile: image1File)
        image2 = Image(contentsOfFile: image2File)


        request = URLRequest(url: url)
        request.httpMethod = "POST"
        serializer = MultipartFormRequestSerializer()
    }

    private func makeFormSerializer() throws -> MultipartFormRequestSerializer {
        let serializer = MultipartFormRequestSerializer()

        guard let videoFileURL = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "mov") else {
            throw URLError.badURL
        }
        guard let videoData = try? Data(contentsOf: videoFileURL) else {
            throw URLError.badURL
        }

        let formPart1 = FormPart(name: "celltowers", filename: "celltowers.jpg",
                                 content: .image(image1, .jpeg(compressionQuality: 0.5)))
        let formPart2 = FormPart(name: "evil_spaceship", filename: "evil_spaceship.png",
                                 content: .image(image2, .png))
        let formPart3 = FormPart(name: "someformlabel", content: .text("some form value"))
        let formPart4 = FormPart(name: "test-video", filename: "test-video.mov", content: .video(videoData, .mov))
        guard let binaryData = ".".data(using: .utf8) else {
            throw TestError.invalidTest
        }
        let formPart5 = FormPart(name: "binary", filename: "binary.bin", content: .binary(binaryData))
        let formPart6 = FormPart(name: "pdf", filename: "pdf.pdf", content: .pdf(Data()))

        serializer.append(formPart: formPart1)
        serializer.append(formPart: formPart2)
        serializer.append(formPart: formPart3)
        serializer.append(formPart: formPart4)
        serializer.append(formPart: formPart5)
        serializer.append(formPart: formPart6)

        return serializer
    }

    func testSerializesDataPerW3Spec() throws {
        let serializer = try makeFormSerializer()

        var newRequest = URLRequest(url: try URL(absoluteString: "http://localhost:3333/post"))
        newRequest.httpMethod = "POST"
        guard let modifiedRequest = try? serializer.serializedRequestWith(request: newRequest, bodyParameters: nil, queryParameters: nil) else {
            XCTFail()
            return
        }

        let client = URLSessionClient()
        let deserializer = JSONResponseDeserializer()

        let receivedResponseExpectation = expectation(description: "recieved response")

        client.begin(request: modifiedRequest) { (data, response, _) in
            do {
                let json = try deserializer.deserializedObjectFrom(response: response, data: data) as? [String: Any]
                let files = json?["files"] as? [String: String]
                let forms = json?["form"] as? [String: String]

                XCTAssert(files?.keys.count == 5)
                XCTAssert(forms?.keys.count == 1)
            }
            catch {
                XCTFail()
            }
            receivedResponseExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testRemovesFormPartContentTypeHeadersIfExplictlyRemoved() throws {
        let serializer = MultipartFormRequestSerializer()

        var formPart = FormPart(name: "celltowers", filename: "celltowers.jpg",
                                content: .image(image1, .jpeg(compressionQuality: 0.5)))
        formPart.contentType = nil
        serializer.append(formPart: formPart)

        var newRequest = URLRequest(url: try URL(absoluteString: "http://localhost:3333/post"))
        newRequest.httpMethod = "POST"
        guard let modifiedRequest = try? serializer.serializedRequestWith(request: newRequest, bodyParameters: nil, queryParameters: nil) else {
            XCTFail()
            return
        }

        guard let httpBody = modifiedRequest.httpBody else {
            XCTFail()
            return
        }

        guard let contentTypeData = "Content-Type".data(using: .utf8) else {
            return
        }

        XCTAssert(httpBody.range(of: contentTypeData) == nil)
    }

    func testDoesntReplaceCustomDefinedHeaders() {
        let customDefaultHeaderFields = [
            "Accept-Language": "FlyingSpaghettiMonster",
            "User-Agent": "Chromebook. Remember those?",
            "Content-Type": "application/its-not-xml-but-it-kind-of-is-aka-soap"
        ]
        request.allHTTPHeaderFields = customDefaultHeaderFields

        guard let modifiedRequest = try? serializer.serializedRequestWith(request: request, bodyParameters: nil) else {
            XCTFail()
            return
        }
        for customHeader in customDefaultHeaderFields {
            XCTAssert(modifiedRequest.value(forHTTPHeaderField: customHeader.0) == customHeader.1)
        }
    }

}
