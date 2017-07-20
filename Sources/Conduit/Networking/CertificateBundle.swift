//
//  CertificateBundle.swift
//  Conduit
//
//  Created by John Hammerlund on 7/18/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation
import Security

public struct CertificateBundle {

    let certificates: [SecCertificate]

    var publicKeys: [SecKey] {
        return self.certificates.flatMap { CertificateBundle.publicKeyFrom(certificate: $0) }
    }

    static private let certificatesInBundle = CertificateBundle.certificatesWithinMainBundle()

    // MARK: Public interface

    /// Creates a new CertificateBundle
    ///
    /// - Parameters:
    ///   - certificatePaths: A list of paths to DER certificates
    public init(certificatePaths: [String]) {
        let certificates = CertificateBundle.certificatesFrom(paths: certificatePaths)
        self.init(certificates: certificates)
    }

    /// Creates a new CertificateBundle
    ///
    /// - Parameters:
    ///   - serverTrust: A server trust, which contains a certificate chain
    public init(serverTrust: SecTrust) {
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        let certificates = (0..<certificateCount).flatMap { SecTrustGetCertificateAtIndex(serverTrust, $0) }

        self.init(certificates: certificates)
    }

    /// Creates a new CertificateBundle
    ///
    /// - Parameters:
    ///   - serverTrust: A list of certificates
    public init(certificates: [SecCertificate]) {
        self.certificates = certificates
    }

    // MARK: Static functions

    /// Searches the main bundle (if running within a bundled application) for DER certificates
    public static func bundleWithCertificatesWithinMainBundle() -> CertificateBundle {
        return CertificateBundle(certificates: self.certificatesInBundle)
    }

    static func publicKeyFrom(certificate: SecCertificate) -> SecKey? {
        var trust: SecTrust?

        let policy = SecPolicyCreateBasicX509()
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)

        assert(status == errSecSuccess, "SecTrustCreateWithCertificates error: \(status)")
        if status == errSecSuccess,
            let trust = trust {
            var result: SecTrustResultType = .invalid
            let evaluateTrustStatus = SecTrustEvaluate(trust, &result)
            assert(evaluateTrustStatus == errSecSuccess, "SecTrustEvaluate error: \(status)")
            if evaluateTrustStatus == errSecSuccess {
                return SecTrustCopyPublicKey(trust)
            }
        }

        return nil
    }

    static private func certificatesWithinMainBundle() -> [SecCertificate] {
        let bundlePaths = Bundle.main.paths(forResourcesOfType: "cer", inDirectory: ".")
        return self.certificatesFrom(paths: bundlePaths)
    }

    static private func certificatesFrom(paths: [String]) -> [SecCertificate] {
        return paths.flatMap { (path) in
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                return SecCertificateCreateWithData(nil, data as CFData)
            }
            return nil
        }
    }

}
