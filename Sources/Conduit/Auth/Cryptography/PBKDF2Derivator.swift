//
//  PBKDF2Derivator.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/26/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation
import CommonCrypto

/// Passphrase-based Key Derivator Function
///
/// Generates 256bit (32 byte) encryption keys derivated from given
/// passphrases of any length, using `kCCPBKDF2` and pseudo-random
/// `kCCPRFHmacAlgSHA1` algorithms.
public final class PBKDF2Derivator {

    public enum Error: Swift.Error {
        case keyDerivationError
    }

    public init() {}

    /// Generate a 256bit (32 byte) encryption key derivated from the given
    /// passphrase, using `kCCPBKDF2` and pseudo-random `kCCPRFHmacAlgSHA1` algorithms.
    ///
    /// - Parameter passphrase: Given passphrase to derivate the key from
    /// - Returns: Derivated 256bit key
    /// - Throws: Exception if key derivation failed
    public func derivateKey(from passphrase: String) throws -> Data {
        let passphraseData = Data(passphrase.utf8)
        let passphraseBytes = Array(passphraseData).map(Int8.init)
        let rounds = UInt32(45_000)

        var outputData = Data(count: kCCKeySizeAES256)
        try outputData.withUnsafeMutableBytes { (outputBytes: UnsafeMutablePointer<UInt8>) in
            let status = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                                              passphraseBytes,
                                              passphraseBytes.count,
                                              nil,
                                              0,
                                              CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
                                              rounds,
                                              outputBytes,
                                              kCCKeySizeAES256)
            guard status == kCCSuccess else {
                throw Error.keyDerivationError
            }
        }
        return outputData
    }
}
