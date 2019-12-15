//
//  AsymmetricKeyPair.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

import Foundation

/// A PKE key-pair
@available(macOS 10.12.1, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
public class AsymmetricKeyPair {
    /// The PKE public key
    public let publicKey: SecKey
    /// The PKE private key
    public let privateKey: SecKey

    /// Creates a new `AsymmetricKeyPair`
    /// - Parameter publicKey: The PKE public key
    /// - Parameter privateKey: The PKE private key
    init(publicKey: SecKey, privateKey: SecKey) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
}
