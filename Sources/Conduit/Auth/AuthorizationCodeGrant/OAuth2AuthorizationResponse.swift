//
//  OAuth2AuthorizationResponse.swift
//  Conduit
//
//  Created by John Hammerlund on 6/28/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// A successful grant of access from an authorization request
public struct OAuth2AuthorizationResponse {

    /// The authorization code to be supplied to the authorization_code grant
    public let code: String

    /// An opaque value used by the client to maintain state between request and the
    /// callback. This is primarily used to prevent CSRF attacks.
    public let state: String?

    /// The acess the user has given to the consuming application.
    /// This value is returned as a comma separated list in the query string.
    public let scope: [String]?

    /// Creates a new OAuth2AuthorizationResponse
    /// - Parameters:
    ///   - code: The authorization code to be supplied to the authorization_code grant
    ///   - state: (Optional) An opaque value used by the client to maintain state between request and the
    ///            callback. This is primarily used to prevent CSRF attacks.
    public init(code: String, state: String? = nil, scope: [String]? = nil) {
        self.code = code
        self.state = state
        self.scope = scope
    }

}
