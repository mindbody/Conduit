//
//  MockCipher.swift
//  Conduit
//
//  Created by John Hammerlund on 12/13/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Security
import Conduit

final class MockCipher: Cipher {

    private lazy var key: Data = {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, 32, &bytes)
        return Data(bytes)
    }()

    func encrypt(data: Data) throws -> Data {
        return xor(data: data)
    }

    func decrypt(data: Data) throws -> Data {
        return xor(data: data)
    }

    private func xor(data: Data) -> Data {
        let bytes = data.enumerated().map { index, _ in
            data[index] ^ key[index % key.count]
        }
        return Data(bytes)
    }

}
