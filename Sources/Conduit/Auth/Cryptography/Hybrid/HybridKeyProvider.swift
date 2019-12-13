//
//  HybridKeyProvider.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

#if XCFRAMEWORK

import Foundation
import Security

/// A type that provides a hybrid-encryption key-pair (symmetric encryption supported by asymmetric keys).
@available(OSXApplicationExtension 10.12.1, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
public protocol HybridKeyProvider {

    /// The algorithm used by provided hybrid keys
    var keyAlgorithm: SecKeyAlgorithm { get }

    /// Creates or retrieves an existing asymmetric key-pair used for hybrid-encryption
    func makeKeyPair() throws -> AsymmetricKeyPair

}

#endif
