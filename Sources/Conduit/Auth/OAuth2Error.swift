//
//  OAuth2Error.swift
//  Conduit
//
//  Created by John Hammerlund on 8/3/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An error that occurs while attempting to grant or access a token
public enum OAuth2Error: Error {

    /// The server application failed to respond within the timeout
    case noResponse

    /// The server response indicates a bad request
    case clientFailure(Data?, HTTPURLResponse?)

    /// An unexpected error occurred within the framework
    case internalFailure

    /// The server application responded with an unexpected failure
    case serverFailure(Data?, HTTPURLResponse)

    /// The network failure has occurred
    case networkFailure
}
