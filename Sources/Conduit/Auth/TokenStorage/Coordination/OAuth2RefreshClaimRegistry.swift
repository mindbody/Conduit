//
//  OAuth2RefreshClaimRegistry.swift
//  Conduit
//
//  Copyright © 2026 MINDBODY. All rights reserved.
//

import Foundation

/// Process-wide atomic refresh claim per client + authorization — the in-process mutual exclusion the check-then-act persisted lock lacks.
final class OAuth2RefreshClaimRegistry {

    static let shared = OAuth2RefreshClaimRegistry()

    private struct Claim {
        let generation: UInt64
        let expiresAt: Date
    }

    private let lock = NSLock()
    private var claims: [String: Claim] = [:]
    private var nextGeneration: UInt64 = 0

    /// Returns an ownership generation for `release(key:generation:)`, or nil if a live claim is held.
    /// Claims expire after `staleAfter` and become stealable, so a hung refresh can never wedge refreshes permanently.
    func tryClaim(key: String, staleAfter: TimeInterval) -> UInt64? {
        lock.lock()
        defer { lock.unlock() }
        if let existing = claims[key], Date() < existing.expiresAt {
            return nil
        }
        nextGeneration += 1
        claims[key] = Claim(generation: nextGeneration, expiresAt: Date().addingTimeInterval(staleAfter))
        return nextGeneration
    }

    /// Returns whether `generation` still owns the claim; gates completion side effects of a possibly-superseded refresh.
    func owns(key: String, generation: UInt64) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return claims[key]?.generation == generation
    }

    /// No-ops unless `generation` owns the current claim — a superseded holder cannot clear its successor's claim.
    func release(key: String, generation: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        guard claims[key]?.generation == generation else {
            return
        }
        claims[key] = nil
    }
}
