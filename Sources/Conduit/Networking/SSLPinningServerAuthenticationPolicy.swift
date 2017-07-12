//
//  SSLPinningServerAuthenticationPolicy.swift
//  Conduit
//
//  Created by John Hammerlund on 7/18/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation

/// A granularity-level of SSL pinning to be performed
public enum SSLPinningType: UInt {
    /// No certificate data is compared
    case none
    /// Only certificate public keys are compared
    case publicKey
    /// Certificate buffers are evaluated byte-for-byte
    case certificateData
}

/// A server authentication policy that evaluates a server trust by ensuring the trust chain
/// is composed of expected certificates and that those certificates are valid
public struct SSLPinningServerAuthenticationPolicy: ServerAuthenticationPolicyType {

    /// A predicate that returns true if the server trust within the provided authentication challenge
    /// should be evaluated
    public typealias SSLPinningServerEvaluationPredicate = (URLAuthenticationChallenge) -> Bool

    let serverEvaluationPredicate: SSLPinningServerEvaluationPredicate
    let certificateBundle: CertificateBundle

    /// If true, then server trusts with invalid certificates will not cause the policy to fail evaluation
    public var allowsInvalidSSLCertificates = false

    /// The granularity of SSL pinning to be performed per authentication challenge
    public var pinningType: SSLPinningType = .publicKey

    /// Initializes an SSLPinningServerAuthenticationPolicy with the given CertificateBundle to pin against and
    /// a predicate to determine when a server trust should be evaluated
    public init(certificates: CertificateBundle, evaluationPredicate: @escaping SSLPinningServerEvaluationPredicate) {
        self.certificateBundle = certificates
        self.serverEvaluationPredicate = evaluationPredicate
    }

    public func evaluate(authenticationChallenge: URLAuthenticationChallenge) -> Bool {
        logger.debug("Received authentication challenge within SSLPinningServerAuthenticationPolicy")

        guard authenticationChallenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust &&
            self.serverEvaluationPredicate(authenticationChallenge) else {
                logger.debug("Server evaluation predicate for SSLPinningServerAuthenticationPolicy returned " +
                             "false -- ignoring authentication challenge")
                return true
        }

        guard let serverTrust = authenticationChallenge.protectionSpace.serverTrust else {
            return true
        }

        logger.debug("Evaluating server trust")
        if !self.evaluate(serverTrust: serverTrust) {
            logger.debug("Server trust evaluation failed")
            return false
        }

        if self.certificateBundle.certificates.isEmpty {
            preconditionFailure("SSL Pinning requires at least one certificate resource to pin against.")
        }

        let serverCertificateBundle = CertificateBundle(serverTrust: serverTrust)

        logger.debug("Evaluating server certificate bundle for SSL pinning")
        return self.evaluate(certificateBundle: serverCertificateBundle)
    }

    func evaluate(certificateBundle: CertificateBundle) -> Bool {
        if self.pinningType == .none {
            logger.debug("SSL pinning type is set to .none -- ignoring")
            return true
        }

        for certificate in certificateBundle.certificates {
            if self.pinningType == .publicKey {
                guard let serverCertificatePublicKey = CertificateBundle.publicKeyFrom(certificate: certificate) else {
                    logger.error("Failed to retrieve public key from one of the certificates")
                    return false
                }
                // Current workaround for Apple's lack of SecKey equality in Swift
                for pinnedPublicKey in self.certificateBundle.publicKeys as [AnyObject] {
                    if pinnedPublicKey.isEqual(serverCertificatePublicKey as AnyObject) {
                        return true
                    }
                }
            }
            else if self.pinningType == .certificateData {
                let pinnedCertificateData = self.certificateBundle.certificates.map {
                    SecCertificateCopyData($0) as Data
                }
                let serverCertificateData = SecCertificateCopyData(certificate) as Data

                if pinnedCertificateData.contains(serverCertificateData) {
                    return true
                }
            }
        }
        logger.error("SSL certificate evaluation failed")
        return false
    }

    func evaluate(serverTrust: SecTrust) -> Bool {
        if self.allowsInvalidSSLCertificates {
            return true
        }

        var result: SecTrustResultType = .invalid
        let status = SecTrustEvaluate(serverTrust, &result)
        let didFailEvaluation = status != errSecSuccess || (result != .unspecified && result != .proceed)
        return !didFailEvaluation
    }

}
