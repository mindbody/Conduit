//
//  OAuth2AuthorizationStrategy.swift
//  Conduit
//
//  Created by John Hammerlund on 6/28/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Directs a resource owner to a request for authorization, where the owner determines whether and how access is permitted.
/// Many OAuth2 applications issue requests through a web page, while others may issue requests through proprietary native applications.
public protocol OAuth2AuthorizationStrategy {

    /// Attempts to begin an Authorization Code grant by directing the resource owner to a request for authorization (often a web page)
    /// - Parameters:
    ///   - request: The request for authorization to be sent to an authorization server
    ///   - completion: The completion handler that fires upon authorization completion/failure
    func authorize(request: OAuth2AuthorizationRequest, completion: @escaping Result<OAuth2AuthorizationResponse>.Block)

}
