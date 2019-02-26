//
//  OAuth2TokenAES256CBCCipherTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class OAuth2TokenAES256CBCCipherTests: XCTestCase {

    func testTokenCipher() throws {
        let encryptionKey = "12345678901234567890123456789012"
        let tokenCipher = try OAuth2TokenAES256CBCCipher(key: encryptionKey)

        let token = BearerToken(accessToken: "foo", expiration: Date.distantFuture)
        let cipherText = try tokenCipher.encrypt(token: token)
        let decrypted: BearerToken = try tokenCipher.decrypt(data: cipherText)
        XCTAssertEqual(token, decrypted)
    }

}
