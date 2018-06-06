//
//  OAuth2RefreshStrategyFactory.swift
//  Conduit
//
//  Created by John Hammerlund on 6/6/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

/// Builds OAuth2TokenGrantStrategies to handle token refreshes
public protocol OAuth2RefreshStrategyFactory {

    /// Creates an OAuth2TokenGrantStrategy to handle a refresh token
    ///
    /// - Parameters:
    ///   - refreshToken: The refresh_token issued from a previous token grant
    ///   - clientConfiguration: The configuration of the OAuth2 client
    /// - Returns: An OAuth2TokenGrantStrategy
    func make(refreshToken: String, clientConfiguration: OAuth2ClientConfiguration) -> OAuth2TokenGrantStrategy
    
}
