//
//  URLSessionClientManager.swift
//  ConduitExample
//
//  Created by John Hammerlund on 6/23/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
import Conduit

/**
 Each newly-initialized URLSessionClient constructs a new network pipeline
 that operates under a single provided URLSessionConfiguration. When copied, the
 constructed pipeline is passed by reference, and all other components (i.e. middleware)
 are passed by value.
 
 In most cases, you will want to define a single URLSessionClient for a single network
 session (makes sense, right?). Usually, this means a single client per OAuth2 application.
 */
class URLSessionClientManager {

    static let shared = URLSessionClientManager()

    /// Handles the session for all API requests to our mock server
    static let localAPISessionClient: URLSessionClient = {
        var sessionClient = URLSessionClient()
        /// In cases where we own the server resources, we'll usually want to pin SSL certificates
        /// For the sake of the demo, we'll keep it simple for now
//        sessionClient.serverAuthenticationPolicies = [myCustomSSLPinningPolicy()]
        return sessionClient
    }()

    /// Used for anonymous requests, or for one-off API requests that require no caching
    static func makeAnonymousClient() -> URLSessionClient {
        return URLSessionClient(sessionConfiguration: URLSessionConfiguration.ephemeral)
    }

}
