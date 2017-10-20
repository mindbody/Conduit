//
//  OAuth2Token.swift
//  Conduit
//
//  Created by John Hammerlund on 7/11/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

public protocol LegacyConvertible {
    var converted: BearerToken { get }
}

/// A token issued from an OAuth2 server application that represents
/// a possession factor (hence "bearer") for a specific user
@available(*, deprecated, message: "NSObject subclasses are being removed; use BearerToken instead.")
public class BearerOAuth2Token: NSObject, NSCoding, DataConvertible, OAuth2Token, LegacyConvertible {

    /// The access token
    public let accessToken: String

    /// The refresh token used to retrieve a new token
    public let refreshToken: String?

    /// The time at which the token expires
    public let expiration: Date

    public var isValid: Bool {
        let minimumExpirationTime: TimeInterval = 900 // 15 minutes
        let minimumExpirationDate = Date().addingTimeInterval(minimumExpirationTime)
        return self.expiration > minimumExpirationDate
    }

    public var authorizationHeaderValue: String {
        return "Bearer \(self.accessToken)"
    }

    /// Creates a new BearerOAuth2Token
    /// - Parameters:
    ///   - accessToken: The access_token
    ///   - refreshToken: (Optional) The refresh_token
    ///   - expiration: The access_token expiration date
    public init(accessToken: String, refreshToken: String? = nil, expiration: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
        super.init()
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let token = aDecoder.decodeObject(forKey: "token") as? String,
            let expiration = aDecoder.decodeObject(forKey: "expiration") as? Date else {
                return nil
        }
        let refreshToken = aDecoder.decodeObject(forKey: "refreshToken") as? String

        self.init(accessToken: token, refreshToken: refreshToken, expiration: expiration)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.accessToken, forKey: "token")
        aCoder.encode(self.expiration, forKey: "expiration")
        aCoder.encode(self.refreshToken, forKey: "refreshToken")
    }

    public override var debugDescription: String {
        let address = String(format: "%p", self)
        let refreshToken = self.refreshToken ?? "nil"
        return "<BearerOAuth2Token:\(address) accessToken:\(accessToken) refreshToken:\(refreshToken) expiration:\(expiration)>"
    }

    public var converted: BearerToken {
        return BearerToken(legacyToken: self)
    }
}
