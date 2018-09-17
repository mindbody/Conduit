//
//  MultipartFormRequestSerializer.swift
//  Conduit
//
//  Created by John Hammerlund on 8/8/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#elseif os(OSX)
    import AppKit
#endif

/// An HTTPRequestSerializer used for constructing multipart/form-data requests
/// - Important: For safety and readability, this class does not currently utilize I/O streams,
/// and it therefore will cause memory pressure for massive uploads. If the need arises,
/// the serializer implementation can be switched to utilize buffers.
/// - Note: This serializer does not currently support mixed boundaries. Support for all other
/// content types can be progressively added as needed.
public final class MultipartFormRequestSerializer: HTTPRequestSerializer {

    static private let CRLF = "\r\n"

    private var formData: [FormPart] = []
    private let contentBoundary = MultipartFormRequestSerializer.randomContentBoundary()

    private lazy var inlineContentBoundary: String = {
        return "--\(contentBoundary)"
    }()

    private lazy var finalContentBoundary: String = {
        return "--\(contentBoundary)--"
    }()

    public override init() {}

    /// Appends the form part to the request body
    /// - Parameters
    ///     - formPart: The part to add to the form
    public func append(formPart: FormPart) {
        formData.append(formPart)
    }

    public override func serialize(request: URLRequest, bodyParameters: Any?) throws -> URLRequest {
        let request = try super.serialize(request: request, bodyParameters: bodyParameters)

        var mutableRequest = request

        if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            mutableRequest.setValue("multipart/form-data; boundary=\(contentBoundary)", forHTTPHeaderField: "Content-Type")
        }

        let httpBody = try makeHTTPBody()

        mutableRequest.setValue(String(httpBody.count), forHTTPHeaderField: "Content-Length")
        mutableRequest.httpBody = httpBody

        return mutableRequest
    }

    private static func randomContentBoundary() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let lettersLength = UInt32(letters.count)

        let randomCharacters = (0..<12).map { _ -> String in
            let offset = Int(arc4random_uniform(lettersLength))
            let characters = letters[letters.index(letters.startIndex, offsetBy: offset)]
            return String(characters)
        }

        return "----------------------------\(randomCharacters.joined())"
    }

    private func encodedDataFrom(string: String) -> Data? {
        return string.data(using: .utf8)
    }

    private func defaultHeadersFor(formPart: FormPart) -> [String: String] {
        var dispositionParts = ["form-data"]
        if let formName = formPart.name {
            dispositionParts.append("name=\"\(formName)\"")
        }
        if let filename = formPart.filename {
            dispositionParts.append("filename=\"\(filename)\"")
        }
        let contentDisposition = dispositionParts.joined(separator: "; ")

        var headers = [
            "Content-Disposition": contentDisposition
        ]
        if let contentType = formPart.contentType {
            headers["Content-Type"] = contentType
        }
        return headers
    }

    private func inlineContentPartDataFrom(formPart: FormPart) throws -> Data {
        var mutableData = Data()
        guard let boundaryData = encodedDataFrom(string: inlineContentBoundary),
            let crlfData = encodedDataFrom(string: MultipartFormRequestSerializer.CRLF) else {
                throw RequestSerializerError.serializationFailure
        }
        mutableData.append(boundaryData)
        mutableData.append(crlfData)

        var headers = defaultHeadersFor(formPart: formPart)
        for (key, value) in formPart.additionalHTTPHeaderFields {
            headers[key] = value
        }
        for header in headers {
            let headerStr = "\(header.0): \(header.1)\(MultipartFormRequestSerializer.CRLF)"
            guard let headerData = encodedDataFrom(string: headerStr) else {
                throw RequestSerializerError.serializationFailure
            }
            mutableData.append(headerData)
        }

        guard let contentData = formPart.contentData() else {
            throw RequestSerializerError.serializationFailure
        }
        mutableData.append(crlfData)
        mutableData.append(contentData)
        mutableData.append(crlfData)

        return mutableData
    }

    private func makeHTTPBody() throws -> Data {
        var mutableBody = Data()

        for formData in formData {
            try mutableBody.append(inlineContentPartDataFrom(formPart: formData))
        }

        let boundaryLine = "\(finalContentBoundary)\(MultipartFormRequestSerializer.CRLF)"
        guard let finalBoundaryData = encodedDataFrom(string: boundaryLine) else {
            throw RequestSerializerError.serializationFailure
        }

        mutableBody.append(finalBoundaryData)

        return mutableBody
    }

}

/// Represents a part of a multipart form with associated content and content information
public struct FormPart {

    /// The name of the form part
    public let name: String?

    /// The filename of the associated content data, if the data is binary
    public let filename: String?

    /// The form part content
    public let content: Content

    /// Additional header fields to apply to the form part (beyond Content-Disposition and Content-Type)
    public var additionalHTTPHeaderFields: [String: String] = [:]

    /// Specifies a custom (or nonexistent) Content-Type for the part headers. Defaults to the
    /// content's MIME type, or application/octet-stream if there is no MIME type.
    public var contentType: String?

    /// Creates a new FormPart with the provided name, filename, and content
    public init(name: String? = nil, filename: String? = nil, content: Content) {
        self.name = name
        self.filename = filename
        self.content = content
        self.contentType = content.mimeType()
    }

    func contentData() -> Data? {
        switch content {
        case let .image(image, type):
            return dataFrom(image: image, type: type)
        case let .video(videoData, _):
            return videoData
        case let .pdf(data):
            return data
        case let .binary(data):
            return data
        case let .text(text):
            return text.data(using: .utf8)
        }
    }

    #if os(OSX)
    private func dataFrom(image: NSImage, type: ImageFormat) -> Data? {
        if let imageRepresentation = image.representations[0] as? NSBitmapImageRep {
            if case .jpeg(let compressionQuality) = type {
                let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: compressionQuality]
                return imageRepresentation.representation(using: .jpeg, properties: properties)
            }
            return imageRepresentation.representation(using: .png, properties: [:])
        }
        return nil
    }
    #endif

    #if os(iOS) || os(tvOS) || os(watchOS)
    private func dataFrom(image: UIImage, type: ImageFormat) -> Data? {
        if case .jpeg(let compressionQuality) = type {
            return image.jpegData(compressionQuality: compressionQuality)
        }
        else {
            return image.pngData()
        }
    }
    #endif

    /// The image format used to compress the image data
    public enum ImageFormat {

        /// JPEG representation with an associated compression quality,
        /// where 0.0 represents the lowest quality and 1.0 represents the highest quality
        case jpeg(compressionQuality: CGFloat)

        /// PNG representation
        case png
    }

    /// The multimedia container format used to describe video data
    public enum VideoFormat {
        /// Quicktime representation
        case mov

        /// MPEG-4 representation
        case mp4

        /// Adobe Flash Video representation
        case flv

        /// Apple HLS format representaiton
        case m3u8

        /// Microsoft interleave representation
        case avi

        /// Windows Media representation
        case wmv
    }

    /// A structure containing form part content information
    public enum Content {

        #if os(OSX)
        /// An image with an associated compression format
        case image(NSImage, ImageFormat)
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        /// An image with an associated compression format
        case image(UIImage, ImageFormat)
        #endif

        /// A video with an associated media container format
        case video(Data, VideoFormat)

        /// PDF Data
        case pdf(Data)

        /// Arbitrary binary data
        case binary(Data)

        /// A plaintext value
        case text(String)

        func mimeType() -> String {
            switch self {
            case .image(_, let imageType):
                return imageMimeType(imageType: imageType)
            case .video(_, let videoType):
                return videoMimeType(videoType: videoType)
            case .pdf:
                return "application/pdf"
            case .binary:
                return "application/octet-stream"
            case .text:
                return "text/plain"
            }
        }

        private func imageMimeType(imageType: FormPart.ImageFormat) -> String {
            switch imageType {
            case .jpeg:
                return "image/jpeg"
            case .png:
                return "image/png"
            }
        }

        private func videoMimeType(videoType: FormPart.VideoFormat) -> String {
            switch videoType {
            case .avi:
                return "video/x-msvideo"
            case .flv:
                return "video/x-flv"
            case .m3u8:
                return "application/x-mpegURL"
            case .mov:
                return "video/quicktime"
            case .mp4:
                return "video/mp4"
            case .wmv:
                return "video/x-ms-wmv"
            }
        }
    }
}
