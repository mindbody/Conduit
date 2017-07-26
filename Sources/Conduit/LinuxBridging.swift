//
//  LinuxBridging.swift
//  Conduit
//
//  Created by John Hammerlund on 7/21/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//
import Foundation

#if os(Linux)

func arc4random_uniform(_ upperBound: UInt32) -> UInt32 {
    srandom(UInt32(truncatingBitPattern: Int(Date.timeIntervalSinceReferenceDate * 1000000)))
    return UInt32(random()) % upperBound
}

public class Image: Equatable {

    public let data: Data

    public static func ==(lhs: Image, rhs: Image) -> Bool {
        return lhs.data == rhs.data
    }

    public init?(data: Data) {
        if data.isEmpty {
            return nil
        }
        self.data = data
    }

}

#endif

func makeNSError(_ error: Error) -> NSError {
    #if os(Linux)
    return NSError(domain: error._domain, code: error._code)
    #else
    return error as NSError
    #endif
    let derp = UInt32(Date.timeIntervalSinceReferenceDate * 1000000)
}
