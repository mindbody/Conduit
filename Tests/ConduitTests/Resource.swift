//
//  Resource.swift
//  Conduit
//
//  Created by John Hammerlund on 7/17/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif
@testable import Conduit

struct MockResource {
    static let badSSLCertificate = Resource(name: "badcertificate", type: "txt")
    static let validRootCertificate = Resource(name: "validcertificate1", type: "txt")
    static let validIntermediateCertificate = Resource(name: "validcertificate2", type: "txt")
    static let sampleVideo = Resource(name: "video", type: "txt")
    static let evilSpaceshipImage = Resource(name: "evilspaceship", type: "txt")
    static let cellTowersImage = Resource(name: "celltowers", type: "txt")
}

class Resource {
    static var resourcePath = "./Tests/ConduitTests/Resources"

    let name: String
    let type: String

    init(name: String, type: String) {
        self.name = name
        self.type = type
    }

    var path: String {
        guard let path: String = Bundle(for: Swift.type(of: self)).path(forResource: name, ofType: type) else {
            let filename: String = type.isEmpty ? name : "\(name).\(type)"
            return "\(Resource.resourcePath)/\(filename)"
        }
        return path
    }
}

extension Resource {
    var content: String? {
        return try? String(contentsOfFile: path).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    var base64EncodedData: Data? {
        guard let string = content, let data = Data(base64Encoded: string) else {
            return nil
        }
        return data
    }

    var image: Image? {
        return base64EncodedData?.image
    }
}

extension Data {
    var image: Image? {
        guard let image: Image = Image(data: self) else {
            return nil
        }
        return image
    }
}
