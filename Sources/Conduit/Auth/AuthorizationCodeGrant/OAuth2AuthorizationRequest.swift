//
//  OAuth2AuthorizationRequest.swift
//  Conduit
//
//  Created by John Hammerlund on 6/28/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Incites a request for authorization from a resource owner
public struct OAuth2AuthorizationRequest {

    /// The OAuth2 client's client_id
    public let clientIdentifier: String

    /// The OAuth2 client's client_secret
    public var clientSecret: String?

    /// The OAuth2 client's redirect_uri. This will usually be configured to a custom URL scheme,
    /// but dynamic deeplinks or client-server redirects are also possible.
    public var redirectURI: URL?

    /// The OAuth2 client's requested scope
    public var scope: String?

    /// An opaque value used by the client to maintain state between request and the
    /// callback. This is primarily used to prevent CSRF attacks.
    public var state: String?

    /// Extension parameters that may be required or otherwise defined by the specific OAuth2 server
    public var additionalParameters: [String: String]?

    /// Creates a new OAuth2AuthorizationRequest
    /// - Parameters:
    ///   - clientIdentifier: The OAuth2 client's client_id
    public init(clientIdentifier: String) {
        self.clientIdentifier = clientIdentifier
    }

}
