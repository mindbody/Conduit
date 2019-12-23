//
//  CryptoError.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

import Foundation

/// An error that occurs during a crypto operation
public struct CryptoError: LocalizedError, Hashable {
    /// The CryptoError code
    public struct Code: Hashable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    /// The error code
    public let code: Code
    /// Additional error details
    public let detail: String?
    public var localizedDescription: String {
        guard let detail = detail else {
            return code.defaultMessage
        }
        return "\(code.defaultMessage) (\(detail))"
    }

    /// Creates a new `CryptoError`
    /// - Parameter code: The error code
    /// - Parameter detail: Additional error details
    public init(code: Code, detail: String? = nil) {
        self.code = code
        self.detail = detail
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}
