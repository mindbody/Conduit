//
//  AuthManager.swift
//  ConduitExample
//
//  Created by John Hammerlund on 6/23/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
import Conduit

/**
 Conduit implements all OAuth2 flows, including authorization code grants.
 
 Each OAuth2 client gets its own OAuth2ClientConfiguration. Its server environment describes the
 server application, and the client configuration itself describes the client registered to
 the given OAuth2 server application.
 */
class AuthManager {

    static let shared = AuthManager()

    init() {
        /// Conduit Auth should typically operate on its own queue to prevent potential threadlocks
        Auth.sessionClient = URLSessionClient(delegateQueue: OperationQueue())
    }

    /// Describes the OAuth2 client registered to our mock server application
    lazy var localClientConfiguration: OAuth2ClientConfiguration = {
        guard let tokenGrantURL = URL(string: "http://localhost:5000/oauth2/issue/token") else {
            preconditionFailure("Token grant URL is invalid")
        }

        let scope = "thing1 thing2 thing3"
        let serverEnvironment = OAuth2ServerEnvironment(scope: scope, tokenGrantURL: tokenGrantURL)
        let clientID = "test_client"
        let clientSecret = "test_secret"
        let guestUsername = "test_user"
        let guestPassword = "hunter2"

        var configuration = OAuth2ClientConfiguration(clientIdentifier: clientID,
                                                      clientSecret: clientSecret,
                                                      environment: serverEnvironment)
        /// In the case that we have a global guest user defined, a client username/password can be set
        /// When sending a request through a pipeline that requires client-level access with a bearer token,
        /// Conduit will automatically attempt a password grant if a valid token doesn't exist
        configuration.guestUsername = guestUsername
        configuration.guestPassword = guestPassword
        return configuration
    }()

    /// Token storage, retrieval, updates, and invalidation is automatically handled by Conduit
    /// except when manually issued from a grant strategy
    lazy var localTokenStore: OAuth2TokenStore = {
        return OAuth2TokenDiskStore(storageMethod: .userDefaults)
    }()

}
