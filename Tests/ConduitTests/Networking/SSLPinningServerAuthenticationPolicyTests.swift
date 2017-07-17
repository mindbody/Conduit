//
//  SSLPinningServerAuthenticationPolicyTests.swift
//  ConduitTests
//
//  Created by John Hammerlund on 7/10/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

fileprivate class MockAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}

class SSLPinningServerAuthenticationPolicyTests: XCTestCase {

    let fakeProtectionSpace = URLProtectionSpace(host: "localhost", port: 3_333, protocol: "http", realm: nil, authenticationMethod: nil)
    var fakeAuthenticationChallenge: URLAuthenticationChallenge!
    var validCertPath: String!
    var invalidCertPath: String!
    var sessionClient: URLSessionClient!

    let succeedingEvaluationPredicate: SSLPinningServerAuthenticationPolicy.SSLPinningServerEvaluationPredicate = { _ in return true }
    var invalidCertificate: SecCertificate!
    var validCertificate: SecCertificate!

    override func setUp() {
        super.setUp()

        fakeAuthenticationChallenge = URLAuthenticationChallenge(protectionSpace: fakeProtectionSpace,
                                                                 proposedCredential: nil,
                                                                 previousFailureCount: 0,
                                                                 failureResponse: nil,
                                                                 error: nil,
                                                                 sender: MockAuthenticationChallengeSender())

        guard let validCertPath = Bundle(for: type(of: self)).path(forResource: "httpbin_cert_valid", ofType: "der") else {
            XCTFail()
            return
        }
        self.validCertPath = validCertPath

        guard let invalidCertPath = Bundle(for: type(of: self)).path(forResource: "badssl", ofType: "der") else {
            XCTFail()
            return
        }
        self.invalidCertPath = invalidCertPath

        sessionClient = URLSessionClient()

        guard let invalidCertificate = CertificateBundle(certificatePaths: [invalidCertPath]).certificates.first else {
            XCTFail()
            return
        }
        self.invalidCertificate = invalidCertificate

        guard let validCertificate = CertificateBundle(certificatePaths: [validCertPath]).certificates.first else {
            XCTFail()
            return
        }
        self.validCertificate = validCertificate
    }

    func testAlwaysSucceedsIfInvalidCertificatesAreAllowed() {
        let certificateBundle = CertificateBundle(certificatePaths: [validCertPath])
        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.allowsInvalidSSLCertificates = true

        var invalidTrust: SecTrust?
        SecTrustCreateWithCertificates(invalidCertificate, nil, &invalidTrust)
        var validTrust: SecTrust?
        SecTrustCreateWithCertificates(validCertificate, nil, &validTrust)

        if let invalidTrust = invalidTrust, let validTrust = validTrust {
            XCTAssertTrue(authenticationPolicy.evaluate(serverTrust: invalidTrust))
            XCTAssertTrue(authenticationPolicy.evaluate(serverTrust: validTrust))
        }
        else {
            XCTFail()
        }
    }

    func testFailsWithUnallowedInvalidCertificates() {
        let certificateBundle = CertificateBundle(certificatePaths: [validCertPath])
        let authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)

        var invalidTrust: SecTrust?
        SecTrustCreateWithCertificates(invalidCertificate, nil, &invalidTrust)

        if let invalidTrust = invalidTrust {
            XCTAssertFalse(authenticationPolicy.evaluate(serverTrust: invalidTrust))
        }
        else {
            XCTFail()
        }
    }

    func testSucceedsForValidUnknownCertificatesWhenPinningSetToNone() {
        let certificateBundle = CertificateBundle(certificatePaths: [validCertPath])
        let mockServerCertificateBundle = CertificateBundle(certificatePaths: [invalidCertPath])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle,
                                                                        evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .none

        XCTAssert(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPublicKeyPinningSucceedsIfPublicKeyFoundInTrustChain() {
        let certificateBundle = CertificateBundle(certificatePaths: [invalidCertPath, validCertPath])
        let mockServerCertificateBundle = CertificateBundle(certificatePaths: [validCertPath])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .publicKey

        XCTAssert(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPublicKeyPinningFailsIfPublicKeyNotFoundInTrustChain() {
        let certificateBundle = CertificateBundle(certificatePaths: [validCertPath])
        let mockServerCertificateBundle = CertificateBundle(certificatePaths: [invalidCertPath])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .publicKey

        XCTAssert(!authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testCertificateDataPinningSucceedsIfCertificateFoundInTrustChain() {
        let certificateBundle = CertificateBundle(certificatePaths: [invalidCertPath, validCertPath])
        let mockServerCertificateBundle = CertificateBundle(certificatePaths: [validCertPath])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .certificateData

        XCTAssert(authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testCertificateDataPinningFailsIfCertificateNotFoundInTrustChain() {
        let certificateBundle = CertificateBundle(certificatePaths: [validCertPath])
        let mockServerCertificateBundle = CertificateBundle(certificatePaths: [invalidCertPath])

        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.pinningType = .certificateData

        XCTAssert(!authenticationPolicy.evaluate(certificateBundle: mockServerCertificateBundle))
    }

    func testPassesIfServerEvaluationPredicateReturnsFalse() {
        let certificateBundle = CertificateBundle(certificatePaths: [validCertPath])

        let authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: { _ in return false })

        XCTAssert(authenticationPolicy.evaluate(authenticationChallenge: fakeAuthenticationChallenge))
    }
}
