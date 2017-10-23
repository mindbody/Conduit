//
//  SSLPinningServerAuthenticationPolicyTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

private class MockAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}

class SSLPinningServerAuthenticationPolicyTests: XCTestCase {

    let fakeProtectionSpace = URLProtectionSpace(host: "localhost", port: 3_333, protocol: "http", realm: nil, authenticationMethod: nil)
    var fakeAuthenticationChallenge: URLAuthenticationChallenge!

    let succeedingEvaluationPredicate: SSLPinningServerAuthenticationPolicy.SSLPinningServerEvaluationPredicate = { _ in
        return true
    }

    override func setUp() {
        super.setUp()
        fakeAuthenticationChallenge = URLAuthenticationChallenge(protectionSpace: fakeProtectionSpace,
                                                                 proposedCredential: nil,
                                                                 previousFailureCount: 0,
                                                                 failureResponse: nil,
                                                                 error: nil,
                                                                 sender: MockAuthenticationChallengeSender())
    }

    private func loadCertificates() throws -> (valid1: SecCertificate, valid2: SecCertificate, invalid: SecCertificate) {
        guard let validCert1 = MockResource.validSSLCertificate1.base64EncodedData,
            let validCert2 = MockResource.validSSLCertificate2.base64EncodedData,
            let invalidCert = MockResource.badSSLCertificate.base64EncodedData,
            let validCertificate1 = SecCertificateCreateWithData(kCFAllocatorMalloc, validCert1 as CFData),
            let validCertificate2 = SecCertificateCreateWithData(kCFAllocatorMalloc, validCert2 as CFData),
            let invalidCertificate = SecCertificateCreateWithData(kCFAllocatorMalloc, invalidCert as CFData) else {
                throw TestError.invalidTest
        }

        return (valid1: validCertificate1, valid2: validCertificate2, invalid: invalidCertificate)
    }

    func testAlwaysSucceedsIfInvalidCertificatesAreAllowed() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.valid1, certificates.valid2])
        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.allowsInvalidSSLCertificates = true

        var invalidTrust: SecTrust?
        SecTrustCreateWithCertificates(certificates.invalid, nil, &invalidTrust)
        var validTrust: SecTrust?
        SecTrustCreateWithCertificates(certificates.valid2, nil, &validTrust)

        if let invalidTrust = invalidTrust, let validTrust = validTrust {
            XCTAssertTrue(authenticationPolicy.evaluate(serverTrust: invalidTrust))
            XCTAssertTrue(authenticationPolicy.evaluate(serverTrust: validTrust))
        }
        else {
            XCTFail("Failed to create trust with certificates")
        }
    }

    func testFailsWithUnallowedInvalidCertificates() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.valid1, certificates.valid2])
        let authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)

        var invalidTrust: SecTrust?
        SecTrustCreateWithCertificates(certificates.invalid, nil, &invalidTrust)

        if let invalidTrust = invalidTrust {
            XCTAssertFalse(authenticationPolicy.evaluate(serverTrust: invalidTrust))
        }
        else {
            XCTFail("Failed to create trust with certificates")
        }
    }

    func testSucceedsForValidUnknownCertificatesWhenPinningSetToNone() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.valid1])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.invalid])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle,
                                                                        evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .none

        XCTAssertTrue(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPublicKeyPinningSucceedsIfPublicKeyFoundInTrustChain() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.invalid, certificates.valid2])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.valid1, certificates.valid2])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .publicKey

        XCTAssertTrue(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPublicKeyPinningFailsIfPublicKeyNotFoundInTrustChain() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.valid1])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.invalid])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .publicKey

        XCTAssertFalse(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testCertificateDataPinningSucceedsIfCertificateFoundInTrustChain() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.invalid, certificates.valid2])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.valid1, certificates.valid2])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .certificateData

        XCTAssertTrue(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testCertificateDataPinningFailsIfCertificateNotFoundInTrustChain() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.valid1])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.invalid])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .certificateData

        XCTAssertFalse(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPassesIfServerEvaluationPredicateReturnsFalse() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.valid1])

        let authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle) { _ in
            return false
        }

        XCTAssertTrue(authenticationPolicy.evaluate(authenticationChallenge: fakeAuthenticationChallenge))
    }
}
