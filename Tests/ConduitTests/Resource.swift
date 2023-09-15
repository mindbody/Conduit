//
//  Resource.swift
//  Conduit
//
//  Created by John Hammerlund on 7/17/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
@testable import Conduit

struct MockResource {
    static let badSSLCertificate = Resource(name: "badcertificate", type: "txt")
    static let validRootCertificate = Resource(name: "validcertificate1", type: "txt")
    static let validIntermediateCertificate = Resource(name: "validcertificate2", type: "txt")
    static let sampleVideo = Resource(name: "video", type: "txt")
    static let evilSpaceshipImage = Resource(name: "evilspaceship", type: "txt")
    static let cellTowersImage = Resource(name: "celltowers", type: "txt")
    static let json = Resource(name: "TestData", type: "json")
}

struct Resource {
    let name: String
    let type: String

    var path: URL {
        let filename: String = type.isEmpty ? name : "\(name).\(type)"
        let bundle = Bundle.module
        let path = bundle.path(forResource: filename, ofType: nil) ?? ""
        return URL(fileURLWithPath: path)
    }
}

extension Resource {
    var content: String? {
        return try? String(contentsOf: path).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    var data: Data? {
        return try? Data(contentsOf: path)
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
