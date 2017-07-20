//
//  OAuth2Token.swift
//  Conduit
//
//  Created by John Hammerlund on 7/11/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// A token used for authorizing user or client requests
public protocol OAuth2Token: class, NSCoding {
    /// Determines whether or not the token is still valid
    var isValid: Bool { get }

    /// The authorization header value used to authorize requests against the server application
    var authorizationHeaderValue: String { get }
}

/// A token issued from an OAuth2 server application that represents
/// a possession factor (hence "bearer") for a specific user
public class BearerOAuth2Token: NSObject, OAuth2Token {

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
        return String(format: "<BearerOAuth2Token:%p accessToken:\(self.accessToken) " +
            "refreshToken:\(self.refreshToken ?? "nil") " +
            "expiration:\(self.expiration)>", self)
    }
}

/// A token that encapsulates a user identifier and a password, most often
/// used for authenticating a client against a server realm
public class BasicOAuth2Token: NSObject, OAuth2Token {

    /// The username or client identifier
    let username: String

    /// The user or client password
    let password: String

    public var isValid: Bool = true

    public var authorizationHeaderValue: String {
        return "Basic \(self.base64EncodedUsernameAndPassword())"
    }

    /// Creates a new BasicOauth2Token
    /// - Parameters:
    ///   - username: The decoded username
    ///   - password: The decoded password
    public init(username: String, password: String) {
        self.username = username
        self.password = password
        super.init()
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let username = aDecoder.decodeObject(forKey: "username") as? String,
            let password = aDecoder.decodeObject(forKey: "password") as? String else {
                return nil
        }

        self.init(username: username, password: password)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.username, forKey: "username")
        aCoder.encode(self.password, forKey: "password")
    }

    public override var debugDescription: String {
        return String(format: "<BasicOAuth2Token:%p username:\(self.username) password:\(self.password)>", self)
    }
}

extension BasicOAuth2Token {
    func base64EncodedUsernameAndPassword() -> String {
        let usernamePasswordString = "\(username):\(password)"
        let base64EncodedData = usernamePasswordString.data(using: String.Encoding.utf8)
        return base64EncodedData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
    }
}

extension BearerOAuth2Token {
    private struct JSONKeys {
        static let accessToken = "access_token"
        static let tokenType = "token_type"
        static let expiresIn = "expires_in"
        static let refreshToken = "refresh_token"
    }

    static func mapFrom(JSON: [String:Any]) -> BearerOAuth2Token? {
        guard let tokenType = JSON[JSONKeys.tokenType] as? String,
            let accessToken = JSON[JSONKeys.accessToken] as? String,
            let expiresIn = JSON[JSONKeys.expiresIn] as? Int else {
                return nil
        }

        let refreshToken = JSON[JSONKeys.refreshToken] as? String

        // RFC6749 5.1: The value of token_type is case-insensitive
        if tokenType.lowercased() != "bearer" {
            return nil
        }

        return BearerOAuth2Token(accessToken: accessToken,
                                 refreshToken: refreshToken,
                                 expiration: Date().addingTimeInterval(TimeInterval(expiresIn)))
    }
}
