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
        let salt = "drowssap"
        let derivator = PBKDF2Derivator()
        let expectation: [UInt8] = [
            0x1F, 0x7F, 0x2E, 0xFF, 0xD3, 0xE3, 0xE1, 0x13,
            0x10, 0x10, 0xA5, 0xC1, 0x8E, 0x13, 0x74, 0xDE,
            0xF3, 0x1F, 0x95, 0x35, 0x16, 0x90, 0xE8, 0x2E,
            0xED, 0xB3, 0xB2, 0x96, 0x86, 0xA8, 0xE1, 0xA7
        ]

        let key = try derivator.derivateKey(from: passphrase, salt: salt)
        XCTAssertEqual(Array(key), expectation)
    }

}
