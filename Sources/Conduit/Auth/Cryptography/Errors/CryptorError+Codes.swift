//
//  CryptorError+Codes.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

import Foundation

extension CryptoError.Code {
    /// An internal error occurred during the crypto operation
    public static let internalOperationFailed = CryptoError.Code(rawValue: -100)
    /// An error occurred while attempting to encrypt the plaintext
    public static let encryptionFailed = CryptoError.Code(rawValue: -101)
    /// An error occurred while attempting to decrypt the ciphertext
    public static let decryptionFailed = CryptoError.Code(rawValue: -102)
    /// The requested crypto operation / algorithm is not supported on this device
    public static let cryptoOperationUnsupported = CryptoError.Code(rawValue: -103)
    /// An error occured while attempting to generate a crypto key
    public static let keyGenerationFailed = CryptoError.Code(rawValue: -104)
}

extension CryptoError.Code {
    var defaultMessage: String {
        switch self {
        case .internalOperationFailed:
            return "An internal error occurred during the crypto operation."
        case .encryptionFailed:
            return "An error occurred while attempting to encrypt the plaintext."
        case .decryptionFailed:
            return "An error occurred while attempting to decrypt the ciphertext."
        case .cryptoOperationUnsupported:
            return "The requested crypto operation / algorithm is not supported on this device."
        case .keyGenerationFailed:
            return "An error occured while attempting to generate a crypto key."
        default:
            return "An unknown error occurred during the crypto operation."
        }
    }
}
