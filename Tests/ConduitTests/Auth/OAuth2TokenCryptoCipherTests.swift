//
//  OAuth2TokenCryptoCipherTests.swift
//  Conduit
//
//  Created by John Hammerlund on 12/13/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

final class OAuth2TokenCryptoCipherTests: XCTestCase {

    func testEncryptsAndDecryptsTokens() throws {
        let cipher = MockCipher()
        let tokenCipher = OAuth2TokenCryptoCipher(cipher: cipher)

        let token = BearerToken(accessToken: "foo", expiration: Date.distantFuture)
        let cipherText = try tokenCipher.encrypt(token: token)
        let decrypted: BearerToken = try tokenCipher.decrypt(data: cipherText)
        XCTAssertEqual(token, decrypted)
        XCTAssertThrowsError(try BearerToken(serializedData: cipherText))
    }

    func testProvidesTokensStoredInPlaintext() throws {
        let cipher = MockCipher()
        let tokenCipher = OAuth2TokenCryptoCipher(cipher: cipher)

        let token = BearerToken(accessToken: "bar", expiration: Date.distantFuture)

        let decrypted: BearerToken = try tokenCipher.decrypt(data: try token.serialized())
        XCTAssertEqual(token, decrypted)
    }

    func testThrowsErrorOnBadDecryption() throws {
        let cipher1 = MockCipher()
        let cipher2 = MockCipher()

        let tokenCipher1 = OAuth2TokenCryptoCipher(cipher: cipher1)
        let tokenCipher2 = OAuth2TokenCryptoCipher(cipher: cipher2)

        let token = BearerToken(accessToken: "baz", expiration: Date.distantFuture)
        let cipherText = try tokenCipher1.encrypt(token: token)

        XCTAssertThrowsError(try tokenCipher2.decrypt(data: cipherText) as BearerToken)
    }

}
