//
//  OAuth2Token.swift
//  Conduit
//
//  Created by John Hammerlund on 8/16/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// A token used for authorizing requests
public protocol OAuth2Token {
    /// The authorization header value used to authorize requests against the server application
    var authorizationHeaderValue: String { get }
}

/// A token issued from an OAuth2 server application that represents
/// a possession factor (hence "bearer") for a specific user
public struct BearerToken: OAuth2Token, DataConvertible, Codable, Equatable {

    /// The access token
    public let accessToken: String

    /// The refresh token used to retrieve a new token
    public let refreshToken: String?

    /// The time at which the token expires
    public let expiration: Date

    public var isValid: Bool {
        let minimumExpirationTime: TimeInterval = 300 // 5 minutes
        let minimumExpirationDate = Date().addingTimeInterval(minimumExpirationTime)
        return self.expiration > minimumExpirationDate
    }

    public var authorizationHeaderValue: String {
        return "Bearer \(self.accessToken)"
    }

    /// Creates a new BearerToken
    /// - Parameters:
    ///   - accessToken: The access_token
    ///   - refreshToken: (Optional) The refresh_token
    ///   - expiration: The access_token expiration date
    public init(accessToken: String, refreshToken: String? = nil, expiration: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }

}

/// A token that encapsulates a user identifier and a password, most often
/// used for authenticating a client against a server realm
public class BasicToken: OAuth2Token {

    /// The username or client identifier
    let username: String

    /// The user or client password
    let password: String

    public var isValid: Bool = true

    public var authorizationHeaderValue: String {
        return "Basic \(base64EncodedUsernameAndPassword())"
    }

    /// Creates a new BasicToken
    /// - Parameters:
    ///   - username: The plaintext username
    ///   - password: The plaintext password
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

extension BearerToken {
    private struct JSONKeys {
        static let accessToken = "access_token"
        static let tokenType = "token_type"
        static let expiresIn = "expires_in"
        static let refreshToken = "refresh_token"
    }

    static func mapFrom(JSON: [String: Any]) -> BearerToken? {
        guard let tokenType = JSON[JSONKeys.tokenType] as? String,
            let accessToken = JSON[JSONKeys.accessToken] as? String else {
                return nil
        }
        let expiration: Date
        if let expiresIn = JSON[JSONKeys.expiresIn] as? Int {
            expiration = Date().addingTimeInterval(TimeInterval(expiresIn))
        }
        else {
            expiration = .distantFuture
        }

        let refreshToken = JSON[JSONKeys.refreshToken] as? String

        // RFC6749 5.1: The value of token_type is case-insensitive
        if tokenType.lowercased() != "bearer" {
            return nil
        }

        return BearerToken(accessToken: accessToken,
                           refreshToken: refreshToken,
                           expiration: expiration)
    }
}

extension BasicToken {
    func base64EncodedUsernameAndPassword() -> String {
        let usernamePasswordString = "\(username):\(password)"
        let base64EncodedData = usernamePasswordString.data(using: String.Encoding.utf8)
        return base64EncodedData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
    }
}
