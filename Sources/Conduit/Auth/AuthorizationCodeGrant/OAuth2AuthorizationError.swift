//
//  OAuth2AuthorizationError.swift
//  Conduit
//
//  Created by John Hammerlund on 6/28/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An error that occured during a request for authorization, as
/// defined by RFC6749 4.1.2.1
public enum OAuth2AuthorizationError: Error {

    /// The request has invalid/missing parameters or is otherwise malformed
    case invalidRequest

    /// The client is not authorized for this request
    case unauthorizedClient

    /// The resource owner or authorization server denied the request
    case accessDenied

    /// The authorization server does not support this request
    case unsupportedResponseType

    /// The requested scope is invalid, unknown, or malformed
    case invalidScope

    /// The server encountered an unexpected server error (HTTP redirects are not
    /// allowed when the HTTP status code falls in the 500 range)
    case serverError

    /// The authorization server is temporarily unable to handle requests (HTTP redirects
    /// are not allowed when the HTTP status code falls in the 500 range)
    case temporarilyUnavailable

    /// The user cancelled the request
    case cancelled

    /// An unknown error occurred during or after the request
    case unknown

    init(errorCode: String) {
        switch errorCode {
        case "invalid_request":
            self = .invalidRequest
        case "unauthorized_client":
            self = .unauthorizedClient
        case "access_denied":
            self = .accessDenied
        case "unsupported_response_type":
            self = .unsupportedResponseType
        case "invalid_scope":
            self = .invalidScope
        case "server_error":
            self = .serverError
        case "temporarily_unavailable":
            self = .temporarilyUnavailable
        default:
            self = .unknown
        }
    }
}
