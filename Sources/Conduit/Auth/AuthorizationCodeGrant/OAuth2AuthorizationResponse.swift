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

    /// Any additional or custom parameters not explicitly stated in the OAuth2 Spec.
    /// This could include accepted scope or granted permissions.
    public let customParameters: [String: String]

    /// Creates a new OAuth2AuthorizationResponse
    /// - Parameters:
    ///   - code: The authorization code to be supplied to the authorization_code grant
    ///   - state: (Optional) An opaque value used by the client to maintain state between request and the
    ///            callback. This is primarily used to prevent CSRF attacks.
    public init(code: String, state: String? = nil, customParameters: [String: String] = [:]) {
        self.code = code
        self.state = state
        self.customParameters = customParameters
    }

}
