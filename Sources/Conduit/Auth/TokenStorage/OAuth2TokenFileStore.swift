//
//  OAuth2TokenFileManagerStore.swift
//  Conduit
//
//  Created by John Hammerlund on 6/12/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

public struct OAuth2TokenFileStoreOptions {

}

public class OAuth2TokenFileStore: OAuth2TokenStore {

    private let storageURL: URL

    public init(storageURL: URL) {
        self.storageURL = storageURL
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
        if let tokenData = tokenData {
            do {
                try tokenData.write(to: storageURL, options: [.atomic])
                return true
            }
            catch {
                return false
            }
        }
        else {
            do {
                try FileManager.default.removeItem(at: storageURL)
                return true
            }
            catch {
                return false
            }
        }
    }

    public func tokenFor<Token>(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Token? where Token: DataConvertible, Token: OAuth2Token {
        guard let data = FileManager.default.contents(atPath: storageURL.path) else {
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
