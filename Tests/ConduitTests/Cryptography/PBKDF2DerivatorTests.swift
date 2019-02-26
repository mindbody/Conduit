//
//  PBKDF2DerivatorTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/26/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class PBKDF2DerivatorTests: XCTestCase {

    // Verify passphrase key derivator works as expected
    // Matched against https://asecuritysite.com/encryption/PBKDF2z
    func testKeyDerivation() throws {
        let passphrase = "password"
        let derivator = PBKDF2Derivator()
        let expectation: [UInt8] = [
            0x98, 0xD4, 0xF2, 0x4A, 0xA2, 0xBA, 0x28, 0x58,
            0x00, 0x2D, 0x5B, 0xF7, 0x73, 0x70, 0x6D, 0xBC,
            0xA3, 0x0C, 0xF8, 0x97, 0x8A, 0x63, 0x21, 0xA6,
            0x20, 0xB5, 0xBF, 0x2B, 0x75, 0x90, 0x43, 0xC1
        ]

        let key = try derivator.derivateKey(from: passphrase)
        XCTAssertEqual(Array(key), expectation)
    }

}
