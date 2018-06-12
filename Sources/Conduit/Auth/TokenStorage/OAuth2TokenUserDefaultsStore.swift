//
//  OAuth2TokenUserDefaultsStore.swift
//  Conduit
//
//  Created by John Hammerlund on 6/12/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

public class OAuth2TokenUserDefaultsStore: OAuth2TokenStore {

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func store<Token>(token: Token?, for client: OAuth2ClientConfiguration, with authorization: OAuth2Authorization)
        -> Bool where Token: DataConvertible, Token: OAuth2Token {
        let tokenData: Data?
        if let token = token {
            tokenData = try? token.serialized()
        }
        else {
            tokenData = nil
        }

        let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
        let userDefaults = UserDefaults.standard
        userDefaults.set(tokenData, forKey: identifier)
        return userDefaults.synchronize()
    }

    public func tokenFor<Token>(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization)
        -> Token? where Token: DataConvertible, Token: OAuth2Token {
        let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
        guard let data = UserDefaults.standard.object(forKey: identifier) as? Data else {
            return nil
        }
        return try? Token(serializedData: data)
    }

    public func storeRefreshState(_ tokenRefreshState: OAuth2TokenRefreshState, client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        return true
    }

    public func tokenRefreshStateFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> OAuth2TokenRefreshState {
        return .inactive
    }

}
