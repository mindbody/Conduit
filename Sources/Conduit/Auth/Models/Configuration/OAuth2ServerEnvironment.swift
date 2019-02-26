//
//  OAuth2ServerEnvironment.swift
//  Conduit
//
//  Created by John Hammerlund on 7/11/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Describes an OAuth2 server application environment
public struct OAuth2ServerEnvironment: Equatable {

    /// The scope of access for which tokens should be granted
    public var scope: String?

    /// The server endpoint that issues new tokens
    public var tokenGrantURL: URL

    /// Creates a new OAuth2ServerEnvironment
    /// - Parameters:
    ///   - scope: The scope of access for which tokens should be granted
    ///   - tokenGrantURL: The server endpoint that issues new tokens
    public init(scope: String? = nil, tokenGrantURL: URL) {
        self.scope = scope
        self.tokenGrantURL = tokenGrantURL
    }

}
