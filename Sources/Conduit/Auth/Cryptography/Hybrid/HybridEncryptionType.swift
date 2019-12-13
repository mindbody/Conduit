//
//  HybridEncryptionType.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

#if XCFRAMEWORK

import Foundation
import Security

/// A symmetric key algorithm supported by asymmetric encryption
/// - eceisAESGCM: Block data is encrypted with AES-GCM, and the AES key is encrypted with
///   an elliptic curve key. This algorithm is usually suggested as keys are smaller and can be stored on
///   the Secure Enclave on applicable devices.
/// - rsaAESGCM: Block data is encrypted with AES-GCM, and the AES key is encrypted with an RSA key. RSA is more applicable
///   for wider system support & generally easier to test / debug due to wider adoption.
@available(OSXApplicationExtension 10.12.1, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
public enum HybridEncryptionType {
    case eceisAESGCM
    case rsaAESGCM
}

@available(OSXApplicationExtension 10.12.1, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
extension HybridEncryptionType {

    var keySize: Int {
        switch self {
        case .eceisAESGCM:
            return 256
        case .rsaAESGCM:
            return 2_048
        }
    }

    var keyType: CFString {
        switch self {
        case .eceisAESGCM:
            return kSecAttrKeyTypeECSECPrimeRandom
        case .rsaAESGCM:
            return kSecAttrKeyTypeRSA
        }
    }

    var algorithm: SecKeyAlgorithm {
        switch self {
        case .eceisAESGCM:
            // EC 256 keys are supported by the Secure Enclave
            return .eciesEncryptionCofactorX963SHA256AESGCM
        case .rsaAESGCM:
            return .rsaEncryptionOAEPSHA256AESGCM
        }
    }

    var supportsSecureEnclaveStorage: Bool {
        return algorithm == .eciesEncryptionCofactorX963SHA256AESGCM
    }

}

#endif
