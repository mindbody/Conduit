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
        let encryptionKey = UUID().uuidString
        let salt = UUID().uuidString
        let tokenCipher = try OAuth2TokenAES256CBCCipher(passphrase: encryptionKey, salt: salt)

        let token = BearerToken(accessToken: "foo", expiration: Date.distantFuture)
        let cipherText = try tokenCipher.encrypt(token: token)
        let decrypted: BearerToken = try tokenCipher.decrypt(data: cipherText)
        XCTAssertEqual(token, decrypted)
    }

    func testForwardsCompatibility() throws {
        let encryptionKey = UUID().uuidString
        let salt = UUID().uuidString
        let sut = try OAuth2TokenAES256CBCCipher(passphrase: encryptionKey, salt: salt)

        let cipher = try AES256CBCCipher(passphrase: encryptionKey, salt: salt)
        let cryptoTokenCipher = OAuth2TokenCryptoCipher(cipher: cipher)

        let token1 = BearerToken(accessToken: UUID().uuidString, expiration: Date.distantFuture)
        let token2 = BearerToken(accessToken: UUID().uuidString, expiration: Date.distantFuture)

        let cipherText1 = try sut.encrypt(token: token1)
        let cipherText2 = try cryptoTokenCipher.encrypt(token: token2)

        let decryptedToken1: BearerToken = try cryptoTokenCipher.decrypt(data: cipherText1)
        let decryptedToken2: BearerToken = try sut.decrypt(data: cipherText2)

        XCTAssertEqual(decryptedToken1, token1)
        XCTAssertEqual(decryptedToken2, token2)
    }

}
