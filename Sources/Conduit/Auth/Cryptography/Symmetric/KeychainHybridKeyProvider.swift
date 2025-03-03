//
//  KeychainHybridKeyProvider.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

import Foundation
import Security
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

/// Provides contextual hybrid-encryption keys via Keychain queries. On supported devices, elliptic-curve keys are stored
/// on the Secure Enclave, providing the maximum application security for key management.
@available(macOS 10.12.1, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
public final class KeychainHybridKeyProvider: HybridKeyProvider {

    private static let itemPrefix = "com.mindbodyonline.Conduit.hybrid-key.secret"
    private static let privateItemLabel = "com.mindbodyonline.Conduit.hybrid-key.private"
    private static let publicItemLabel = "com.mindbodyonline.Conduit.hybrid-key.public"

    private let accessGroup: String?
    private let accessibility: CFString
    private let itemTag: String
    private lazy var tagData: Data? = {
        itemTag.data(using: .utf8)
    }()
    private let encryptionType: HybridEncryptionType
    public private(set) lazy var keyAlgorithm: SecKeyAlgorithm = encryptionType.algorithm
    /// If true, then applicable keys will be stored on the Secure Enclave on supported devices. Defaults to `true`
    /// - Important: Mac applications require entitlements (and therefore, valid codesigning) in order to support this.
    ///   Otherwise, this will trigger an `errSecMissingEntitlements`.
    public var prefersSecureEnclaveStorage: Bool = true

    private lazy var itemQuery: [String: Any] = {
        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: encryptionType.keyType
        ]
        query[kSecAttrAccessGroup as String] = accessGroup
        query[kSecAttrApplicationTag as String] = tagData
        return query
    }()
    private lazy var canUseSecureEnclave: Bool = {
        guard prefersSecureEnclaveStorage else {
            return false
        }
        #if !targetEnvironment(simulator) && !os(watchOS) && !os(tvOS)
        if encryptionType.supportsSecureEnclaveStorage, #available(OSX 10.12.2, *) {
            // Unfortunately, the only way to determine if the secure enclave is available is via determining biometric capabilities.
            // Attempting to store items in the secure enclave on unsupported devices will result in a crash on certain versions.
            var error: NSError?
            if LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                return true
            }
            guard let errorCode = error.flatMap({ LAError.Code(rawValue: $0.code) }) else {
                return false
            }
            return errorCode != .biometryNotAvailable
        }
        #endif
        return false
    }()

    /// Creates a new `KeychainHybridKeyProvider`
    /// - Parameter context: The context used to identify the key-pair (used for item tag data)
    /// - Parameter accessibility: The Keychain accessibility of the private key. Defaults to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
    /// - Parameter encryptionType: The key-pair encryption algorithm type. Defaults to `.eceisAESGCM` (elliptic-curve)
    /// - Parameter accessGroup: (Optional) The shared Keychain Application Group Identifier
    public init(context: String, accessibility: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                encryptionType: HybridEncryptionType = .eceisAESGCM, accessGroup: String? = nil) {
        self.itemTag = "\(KeychainHybridKeyProvider.itemPrefix).\(context)"
        self.accessibility = accessibility
        self.encryptionType = encryptionType
        self.accessGroup = accessGroup
    }

    private func makeNewKeyPair() throws -> AsymmetricKeyPair {
        guard let tag = tagData else {
            throw CryptoError(code: .keyGenerationFailed, detail: "Item context is not encodable in UTF-8")
        }

        var privateKeyAttributes: [String: Any] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrLabel as String: KeychainHybridKeyProvider.privateItemLabel,
            kSecAttrApplicationTag as String: tag
        ]
        let publicKeyAttributes: [String: Any] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrLabel as String: KeychainHybridKeyProvider.publicItemLabel,
            kSecAttrApplicationTag as String: tag,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        if canUseSecureEnclave {
            // kSecAttrAccessControl is mutually exclusive with kSecAttrAccessible (in the documentation) and the .privateKeyUsage flag
            // returns an errSecParam on macOS when not stored on the Secure Enclave. Additionally, previous versions of iOS will crash
            // or return an error if provided a kSecAttrAccessControl with empty flags. In other words, we should only provide this
            // if we know that we can use the Secure Enclave or if we add more flags in the future.
            let privateAccessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, accessibility, .privateKeyUsage, nil)
            privateKeyAttributes[kSecAttrAccessControl as String] = privateAccessControl
        }
        else {
            privateKeyAttributes[kSecAttrAccessible as String] = accessibility
        }

        var attributes: [String: Any] = [
            kSecAttrKeyType as String: encryptionType.keyType,
            kSecAttrKeySizeInBits as String: encryptionType.keySize,
            kSecPrivateKeyAttrs as String: privateKeyAttributes,
            kSecPublicKeyAttrs as String: publicKeyAttributes
        ]
        attributes[kSecAttrAccessGroup as String] = accessGroup
        attributes[kSecAttrApplicationTag as String] = tagData
        if canUseSecureEnclave {
            attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        }

        var publicKeyRef, privateKeyRef: SecKey?
        let status = SecKeyGeneratePair(attributes as CFDictionary, &publicKeyRef, &privateKeyRef)
        guard status == errSecSuccess, let publicKey = publicKeyRef, let privateKey = privateKeyRef else {
            throw CryptoError(code: .keyGenerationFailed, detail: "OSStatus \(status)")
        }

        return AsymmetricKeyPair(publicKey: publicKey, privateKey: privateKey)
    }

    private func retrieveExistingKey(isPublic: Bool) throws -> SecKey? {
        var query = itemQuery
        query[kSecReturnRef as String] = true
        query[kSecAttrLabel as String] = isPublic ? KeychainHybridKeyProvider.publicItemLabel : KeychainHybridKeyProvider.privateItemLabel

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw CryptoError(code: .internalOperationFailed, detail: "OSStatus \(status)")
        }
        if let item = item {
            // https://bugs.swift.org/browse/SR-4209
            // swiftlint:disable force_cast
            return (item as! SecKey)
            // swiftlint:enable force_cast
        }
        return nil
    }

    public func makeKeyPair() throws -> AsymmetricKeyPair {
        if let publicKey = try retrieveExistingKey(isPublic: true), let privateKey = try retrieveExistingKey(isPublic: false) {
            return AsymmetricKeyPair(publicKey: publicKey, privateKey: privateKey)
        }
        return try makeNewKeyPair()
    }

    /// Deletes the stored key-pair, if one exists
    /// - Returns: A `Bool` indicating whether the deletion was successful
    @discardableResult
    public func deleteKey() -> Bool {
        guard tagData != nil else {
            return false
        }
        var query = itemQuery
        query[kSecAttrLabel as String] = KeychainHybridKeyProvider.publicItemLabel
        query[kSecReturnRef as String] = true
        let publicDeletionStatus = SecItemDelete(query as CFDictionary)

        query[kSecAttrLabel as String] = KeychainHybridKeyProvider.privateItemLabel
        let privateDeletionStatus = SecItemDelete(query as CFDictionary)

        var didSucceed = true

        if publicDeletionStatus != errSecSuccess {
            logger.info("KeychainAsymmetricKeyProvider: Error deleting public key with OSStatus \(publicDeletionStatus)")
            didSucceed = false
        }
        if privateDeletionStatus != errSecSuccess {
            logger.info("KeychainAsymmetricKeyProvider: Error deleting private key with OSStatus \(publicDeletionStatus)")
            didSucceed = false
        }
        return didSucceed
    }

}
