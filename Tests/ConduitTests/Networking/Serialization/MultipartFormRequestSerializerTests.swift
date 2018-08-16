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

    private func makeRequest() throws -> URLRequest {
        let url = try URL(absoluteString: "http://localhost:3333")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }

    private func makeFormSerializer() throws -> MultipartFormRequestSerializer {
        let serializer = MultipartFormRequestSerializer()

        guard let image1 = MockResource.cellTowersImage.image, let image2 = MockResource.evilSpaceshipImage.image,
            let videoData = MockResource.sampleVideo.base64EncodedData else {
                throw TestError.invalidTest
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
        guard let modifiedRequest = try? serializer.serialize(request: newRequest, bodyParameters: nil) else {
            XCTFail("Serialization failed")
            return
        }

        let client = URLSessionClient()
        let deserializer = JSONResponseDeserializer()

        let receivedResponseExpectation = expectation(description: "recieved response")

        client.begin(request: modifiedRequest) { data, response, _ in
            do {
                let json = try deserializer.deserialize(response: response, data: data) as? [String: Any]
                let files = json?["files"] as? [String: String]
                let forms = json?["form"] as? [String: String]

                XCTAssertEqual(files?.keys.count, 5)
                XCTAssertEqual(forms?.keys.count, 1)
            }
            catch {
                XCTFail("Request failed")
            }
            receivedResponseExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testRemovesFormPartContentTypeHeadersIfExplictlyRemoved() throws {
        let serializer = MultipartFormRequestSerializer()

        guard let image1 = MockResource.cellTowersImage.image else {
            throw TestError.invalidTest
        }

        var formPart = FormPart(name: "celltowers", filename: "celltowers.jpg", content: .image(image1, .jpeg(compressionQuality: 0.5)))
        formPart.contentType = nil
        serializer.append(formPart: formPart)

        var newRequest = URLRequest(url: try URL(absoluteString: "http://localhost:3333/post"))
        newRequest.httpMethod = "POST"
        let modifiedRequest = try serializer.serialize(request: newRequest, bodyParameters: nil)

        guard let httpBody = modifiedRequest.httpBody else {
            XCTFail("No body")
            return
        }

        guard let contentTypeData = "Content-Type".data(using: .utf8) else {
            return
        }

        XCTAssertNil(httpBody.range(of: contentTypeData))
    }

    func testDoesntReplaceCustomDefinedHeaders() throws {
        var request = try makeRequest()
        let serializer = MultipartFormRequestSerializer()

        let customDefaultHeaderFields = [
            "Accept-Language": "FlyingSpaghettiMonster",
            "User-Agent": "Chromebook. Remember those?",
            "Content-Type": "application/its-not-xml-but-it-kind-of-is-aka-soap"
        ]
        request.allHTTPHeaderFields = customDefaultHeaderFields

        let modifiedRequest = try serializer.serialize(request: request, bodyParameters: nil)
        for customHeader in customDefaultHeaderFields {
            XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: customHeader.0), customHeader.1)
        }
    }

}
