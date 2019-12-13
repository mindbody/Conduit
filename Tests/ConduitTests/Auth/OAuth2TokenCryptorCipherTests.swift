//
//  OAuth2TokenCryptorCipherTests.swift
//  Conduit
//
//  Created by John Hammerlund on 12/13/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

final class OAuth2TokenCryptorCipherTests: XCTestCase {

    func testEncryptsAndDecryptsTokens() throws {
        let cryptor = MockCryptor()
        let tokenCipher = OAuth2TokenCryptorCipher(cryptor: cryptor)

        let token = BearerToken(accessToken: "foo", expiration: Date.distantFuture)
        let cipherText = try tokenCipher.encrypt(token: token)
        let decrypted: BearerToken = try tokenCipher.decrypt(data: cipherText)
        XCTAssertEqual(token, decrypted)
        XCTAssertThrowsError(try BearerToken(serializedData: cipherText))
    }

    func testProvidesTokensStoredInPlaintext() throws {
        let cryptor = MockCryptor()
        let tokenCipher = OAuth2TokenCryptorCipher(cryptor: cryptor)

        let token = BearerToken(accessToken: "bar", expiration: Date.distantFuture)

        let decrypted: BearerToken = try tokenCipher.decrypt(data: try token.serialized())
        XCTAssertEqual(token, decrypted)
    }

    func testThrowsErrorOnBadDecryption() throws {
        let cryptor1 = MockCryptor()
        let cryptor2 = MockCryptor()

        let tokenCipher1 = OAuth2TokenCryptorCipher(cryptor: cryptor1)
        let tokenCipher2 = OAuth2TokenCryptorCipher(cryptor: cryptor2)

        let token = BearerToken(accessToken: "baz", expiration: Date.distantFuture)
        let cipherText = try tokenCipher1.encrypt(token: token)

        XCTAssertThrowsError(try tokenCipher2.decrypt(data: cipherText) as BearerToken)
    }

}
