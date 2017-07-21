//
//  LinuxBridging.swift
//  Conduit
//
//  Created by John Hammerlund on 7/21/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//
#if os(Linux)

import Foundation

func arc4random_uniform(_ upperBound: UInt32) -> UInt32 {
    srandom(UInt32(time(nil)))
    return UInt32(random())
}

#endif
