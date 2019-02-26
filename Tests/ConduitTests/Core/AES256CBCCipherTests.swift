//
//  AES256CBCCipherTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class AES256CBCCipherTests: XCTestCase {

    // Data from https://www.devglan.com/online-tools/aes-encryption-decryption
    func testCannedData() throws {
        let key = "12345678901234567890123456789012"
        let vector = "1234567890123456"
        let plaintext = "Hello world!"
        let expected: [UInt8] = [0x47, 0x31, 0x83, 0x88, 0x82, 0x04, 0x2C, 0xE8, 0xAF, 0x60,
                                 0x24, 0xF3, 0x41, 0x4C, 0x10, 0x92]

        let cipher = try AES256CBCCipher(key: key, iv: vector)
        let encrypted = try cipher.encrypt(data: plaintext.data(using: .utf8) ?? Data())
        XCTAssertEqual(Array(encrypted), expected)
        let decrypted = try cipher.decrypt(data: encrypted)
        XCTAssertEqual(String(data: decrypted, encoding: .utf8), plaintext)
    }

}
