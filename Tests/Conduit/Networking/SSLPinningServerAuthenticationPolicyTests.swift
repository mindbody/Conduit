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
    @objc func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    @objc func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    @objc func cancel(_ challenge: URLAuthenticationChallenge) {}
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

        fakeAuthenticationChallenge = URLAuthenticationChallenge(protectionSpace: fakeProtectionSpace, proposedCredential: nil, previousFailureCount: 0, failureResponse: nil, error: nil, sender: MockAuthenticationChallengeSender())
        validCertPath = Bundle(for: type(of: self)).path(forResource: "httpbin_cert_valid", ofType: "der")!
        invalidCertPath = Bundle(for: type(of: self)).path(forResource: "badssl", ofType: "der")!
        sessionClient = URLSessionClient()
        invalidCertificate = CertificateBundle(certificatePaths: [invalidCertPath]).certificates.first!
        validCertificate = CertificateBundle(certificatePaths: [validCertPath]).certificates.first!
    }

    func testAlwaysSucceedsIfInvalidCertificatesAreAllowed() {
        let certificateBundle = CertificateBundle(certificatePaths: [validCertPath])
        var authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)
        authenticationPolicy.allowsInvalidSSLCertificates = true

        var invalidTrust: SecTrust?
        SecTrustCreateWithCertificates(invalidCertificate, nil, &invalidTrust)
        var validTrust: SecTrust?
        SecTrustCreateWithCertificates(validCertificate, nil, &validTrust)

        XCTAssert(authenticationPolicy.evaluate(serverTrust: invalidTrust!))
        XCTAssert(authenticationPolicy.evaluate(serverTrust: validTrust!))
    }

    func testFailsWithUnallowedInvalidCertificates() {
        let certificateBundle = CertificateBundle(certificatePaths: [validCertPath])
        let authenticationPolicy = SSLPinningServerAuthenticationPolicy(certificates: certificateBundle, evaluationPredicate: succeedingEvaluationPredicate)

        var invalidTrust: SecTrust?
        SecTrustCreateWithCertificates(invalidCertificate, nil, &invalidTrust)

        XCTAssert(!authenticationPolicy.evaluate(serverTrust: invalidTrust!))
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
