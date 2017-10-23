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

private struct TestCertificateBundle {
    let validRootCertificate: SecCertificate
    let validIntermediateCertificate: SecCertificate
    let invalidCertificate: SecCertificate
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

    private func loadCertificates() throws -> TestCertificateBundle {
        guard let validCert1 = MockResource.validRootCertificate.base64EncodedData,
            let validCert2 = MockResource.validIntermediateCertificate.base64EncodedData,
            let invalidCert = MockResource.badSSLCertificate.base64EncodedData,
            let validCertificate1 = SecCertificateCreateWithData(kCFAllocatorMalloc, validCert1 as CFData),
            let validCertificate2 = SecCertificateCreateWithData(kCFAllocatorMalloc, validCert2 as CFData),
            let invalidCertificate = SecCertificateCreateWithData(kCFAllocatorMalloc, invalidCert as CFData) else {
                throw TestError.invalidTest
        }

        return TestCertificateBundle(validRootCertificate: validCertificate1,
                                     validIntermediateCertificate: validCertificate2,
                                     invalidCertificate: invalidCertificate)
    }

    func testAlwaysSucceedsIfInvalidCertificatesAreAllowed() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.validRootCertificate, certificates.validIntermediateCertificate])
        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.allowsInvalidSSLCertificates = true

        var invalidTrust: SecTrust?
        SecTrustCreateWithCertificates(certificates.invalidCertificate, nil, &invalidTrust)
        var validTrust: SecTrust?
        SecTrustCreateWithCertificates(certificates.validIntermediateCertificate, nil, &validTrust)

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
        let certificateBundle = CertificateBundle(certificates: [certificates.validRootCertificate, certificates.validIntermediateCertificate])
        let authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)

        var invalidTrust: SecTrust?
        SecTrustCreateWithCertificates(certificates.invalidCertificate, nil, &invalidTrust)

        if let invalidTrust = invalidTrust {
            XCTAssertFalse(authenticationPolicy.evaluate(serverTrust: invalidTrust))
        }
        else {
            XCTFail("Failed to create trust with certificates")
        }
    }

    func testSucceedsForValidUnknownCertificatesWhenPinningSetToNone() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.validRootCertificate])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.invalidCertificate])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle,
                                                                        evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .none

        XCTAssertTrue(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPublicKeyPinningSucceedsIfPublicKeyFoundInTrustChain() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.invalidCertificate, certificates.validIntermediateCertificate])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.validRootCertificate, certificates.validIntermediateCertificate])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .publicKey

        XCTAssertTrue(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPublicKeyPinningFailsIfPublicKeyNotFoundInTrustChain() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.validRootCertificate])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.invalidCertificate])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .publicKey

        XCTAssertFalse(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testCertificateDataPinningSucceedsIfCertificateFoundInTrustChain() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.invalidCertificate, certificates.validIntermediateCertificate])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.validRootCertificate, certificates.validIntermediateCertificate])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .certificateData

        XCTAssertTrue(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testCertificateDataPinningFailsIfCertificateNotFoundInTrustChain() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.validRootCertificate])
        let mockServerCertificateBundle = CertificateBundle(certificates: [certificates.invalidCertificate])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .certificateData

        XCTAssertFalse(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPassesIfServerEvaluationPredicateReturnsFalse() throws {
        let certificates = try loadCertificates()
        let certificateBundle = CertificateBundle(certificates: [certificates.validRootCertificate])

        let authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle) { _ in
            return false
        }

        XCTAssertTrue(authenticationPolicy.evaluate(authenticationChallenge: fakeAuthenticationChallenge))
    }
}
