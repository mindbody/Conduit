//
//  OAuth2TokenEncryptor.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation

public final class OAuth2TokenAES256CBCCipher: OAuth2TokenCipher {

    let cipher: AES256CBCCipher

    public init(key: String) throws {
        cipher = try AES256CBCCipher(key: key)
    }

    public func encrypt<Token>(token: Token) throws -> Data where Token: DataConvertible, Token: OAuth2Token {
        let tokenData = try token.serialized()
        return try cipher.encrypt(data: tokenData)
    }

    public func decrypt<Token>(data cipherData: Data) throws -> Token where Token: DataConvertible, Token: OAuth2Token {
        let data = try cipher.decrypt(data: cipherData)
        return try Token(serializedData: data)
    }
}
