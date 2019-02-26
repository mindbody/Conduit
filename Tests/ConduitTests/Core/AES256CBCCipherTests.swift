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

    // Verify encrypted data actually matches AES-256 CBC
    // Validated against data from https://www.devglan.com/online-tools/aes-encryption-decryption
    func testHelloWorld() throws {
        let key = "12345678901234567890123456789012"
        let vector = "1234567890123456"
        let plaintext = "Hello world!"
        let expected: [UInt8] = [
            0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36,
            0x47, 0x31, 0x83, 0x88, 0x82, 0x04, 0x2C, 0xE8, 0xAF, 0x60, 0x24, 0xF3, 0x41, 0x4C, 0x10, 0x92
        ]

        let cipher = try AES256CBCCipher(key: key)
        let encrypted = try cipher.encrypt(data: plaintext.data(using: .utf8) ?? Data(),
                                           iv: vector.data(using: .utf8) ?? Data())
        XCTAssertEqual(Array(encrypted), expected)
        let decrypted = try cipher.decrypt(data: encrypted)
        XCTAssertEqual(String(data: decrypted, encoding: .utf8), plaintext)
    }

    func testInvalidKey() throws {
        let key = ""
        do {
            _ = try AES256CBCCipher(key: key)
            XCTFail("Expected to throw")
        }
        catch AES256CBCCipher.CipherError.invalidKey {
            // Pass
        }
        catch {
            XCTFail("Unknown error")
        }
    }

}
