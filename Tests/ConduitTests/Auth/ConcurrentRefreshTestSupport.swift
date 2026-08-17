//
//  ConcurrentRefreshTestSupport.swift
//  Conduit
//
//  Copyright © 2026 MINDBODY. All rights reserved.
//

import Foundation
@testable import Conduit

/// Records every grant issued and returns rotated tokens like a real token endpoint.
final class RecordingRefreshStrategyFactory: OAuth2RefreshStrategyFactory {
    private let recordLock = NSLock()
    private(set) var issuedGrantRefreshTokens: [String] = []

    func make(refreshToken: String, clientConfiguration: OAuth2ClientConfiguration) -> OAuth2TokenGrantStrategy {
        recordLock.lock()
        issuedGrantRefreshTokens.append(refreshToken)
        let rotation = issuedGrantRefreshTokens.count
        recordLock.unlock()
        let rotatedToken = BearerToken(accessToken: "ACCESS_\(rotation)",
                                       refreshToken: "ROTATED_\(rotation)",
                                       expiration: Date().addingTimeInterval(3_600))
        return StubbedGrantStrategy(token: rotatedToken)
    }
}

/// Completes asynchronously with a fixed token, mimicking token-endpoint latency.
struct StubbedGrantStrategy: OAuth2TokenGrantStrategy {
    let token: BearerToken

    func issueToken(completion: @escaping (Result<BearerToken>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(50)) {
            completion(.value(token))
        }
    }

    func issueToken() throws -> BearerToken {
        return token
    }
}

/// Fails with clientFailure only after the test signals, so the claim can go stale while the grant is in flight.
struct GatedFailureStrategy: OAuth2TokenGrantStrategy {
    let proceed: DispatchSemaphore

    func issueToken(completion: @escaping (Result<BearerToken>) -> Void) {
        DispatchQueue.global().async {
            self.proceed.wait()
            completion(.error(OAuth2Error.clientFailure(nil, nil)))
        }
    }

    func issueToken() throws -> BearerToken {
        throw OAuth2Error.clientFailure(nil, nil)
    }
}

final class GatedFailureStrategyFactory: OAuth2RefreshStrategyFactory {
    let proceed = DispatchSemaphore(value: 0)

    func make(refreshToken: String, clientConfiguration: OAuth2ClientConfiguration) -> OAuth2TokenGrantStrategy {
        GatedFailureStrategy(proceed: proceed)
    }
}

/// Succeeds with a rotated token only after the test signals, so the claim can go stale while the grant is in flight.
struct GatedSuccessStrategy: OAuth2TokenGrantStrategy {
    let proceed: DispatchSemaphore
    let token: BearerToken

    func issueToken(completion: @escaping (Result<BearerToken>) -> Void) {
        DispatchQueue.global().async {
            self.proceed.wait()
            completion(.value(token))
        }
    }

    func issueToken() throws -> BearerToken {
        return token
    }
}

final class GatedSuccessStrategyFactory: OAuth2RefreshStrategyFactory {
    let proceed = DispatchSemaphore(value: 0)

    func make(refreshToken: String, clientConfiguration: OAuth2ClientConfiguration) -> OAuth2TokenGrantStrategy {
        GatedSuccessStrategy(proceed: proceed,
                             token: BearerToken(accessToken: "LATE", refreshToken: "RT_LATE",
                                                expiration: Date().addingTimeInterval(3_600)))
    }
}

/// Returns the expired token for the first read and the fresh token afterwards — scripting the
/// "another refresh persisted while we raced" interleavings deterministically.
final class ScriptedReadTokenStore: OAuth2TokenStore {
    private let underlying = OAuth2TokenMemoryStore()
    private let readLock = NSLock()
    private var reads = 0
    let expiredToken = BearerToken(accessToken: "EXPIRED", refreshToken: "RT_OLD", expiration: Date())
    let freshToken = BearerToken(accessToken: "FRESH", refreshToken: "RT_NEW",
                                 expiration: Date().addingTimeInterval(3_600))

    @discardableResult
    func store<Token: OAuth2Token & DataConvertible>(token: Token?, for client: OAuth2ClientConfiguration,
                                                     with authorization: OAuth2Authorization) -> Bool {
        underlying.store(token: token, for: client, with: authorization)
    }

    func tokenFor<Token: OAuth2Token & DataConvertible>(client: OAuth2ClientConfiguration,
                                                        authorization: OAuth2Authorization) -> Token? {
        readLock.lock()
        defer { readLock.unlock() }
        reads += 1
        return (reads == 1 ? expiredToken : freshToken) as? Token
    }

    @discardableResult
    func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration,
                          authorization: OAuth2Authorization) -> Bool {
        underlying.lockRefreshToken(timeout: timeout, client: client, authorization: authorization)
    }

    @discardableResult
    func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        underlying.unlockRefreshTokenFor(client: client, authorization: authorization)
    }

    func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date? {
        underlying.refreshTokenLockExpirationFor(client: client, authorization: authorization)
    }
}
