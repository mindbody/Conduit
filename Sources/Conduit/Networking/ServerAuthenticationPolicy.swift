//
//  ServerAuthenticationPolicy.swift
//  Conduit
//
//  Created by John Hammerlund on 7/18/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation

/// Defines a type that is responsible for evaluating an authentication challenge from a server
public protocol ServerAuthenticationPolicyType {
    /// Indicates whether or not the policy passes with the provided authentication challenge
    /// - Parameters:
    ///     - authenticationChallenge: The authentication challenge sent from a server
    /// - Returns: A Bool indicating whether or not the policy passed
    func evaluate(authenticationChallenge: URLAuthenticationChallenge) -> Bool
}
