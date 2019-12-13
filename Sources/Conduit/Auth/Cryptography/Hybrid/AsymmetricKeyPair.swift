//
//  AsymmetricKeyPair.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

import Foundation

/// A PKE key-pair
@available(OSXApplicationExtension 10.12.1, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
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
