//
//  OAuth2AuthorizationRedirectHandler.swift
//  Conduit
//
//  Created by John Hammerlund on 6/28/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

#if os(iOS)

import UIKit

/** 
 Handles authorization redirects via custom URL schemes.
 ### Usage:
 ```
 /// AppDelegate.swift

 func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    OAuth2AuthorizationRedirectHandler.default.authorizationURLScheme = "x-my-custom-scheme"
    ...
    return true
 }
 func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    if OAuth2AuthorizationRedirectHandler.default.handleOpen(url) {
        return true
    }
 }
 ```
 */
public class OAuth2AuthorizationRedirectHandler: NSObject {

    /// The default singleton handler. Useful for applications that are only concerned with a single authorization server.
    /// - Warning: This handler's authorizationURLScheme must be set before being used.
    @objc(defaultHandler)
    public static let `default` = OAuth2AuthorizationRedirectHandler(authorizationURLScheme: "")

    private var activeHandler: Result<OAuth2AuthorizationResponse>.Block?
    /// The custom URL scheme used for handling authorization responses
    public var authorizationURLScheme: String

    /// Creates a new OAuth2AuthorizationRedirectHandler
    /// - Parameters:
    ///   - authorizationURLScheme: The custom URL scheme used for handling authorization responses
    public init(authorizationURLScheme: String) {
        self.authorizationURLScheme = authorizationURLScheme
    }

    /// Handles a custom URL scheme received through the AppDelegate
    /// - Parameters:
    ///   - url: The URL sent to the application
    public final func handleOpen(url: URL) -> Bool {
        precondition(!authorizationURLScheme.isEmpty, "Redirect handler URL scheme must be set")
        defer {
            activeHandler = nil
        }
        var shouldHandleURL = false

        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return shouldHandleURL
        }

        guard urlComponents.scheme == authorizationURLScheme else {
            return shouldHandleURL
        }
        shouldHandleURL = true

        guard let queryItems = urlComponents.queryItems else {
            activeHandler?(.error(OAuth2AuthorizationError.unknown))
            return shouldHandleURL
        }

        var queryItemsDict: [String : String] = [:]

        for item in queryItems {
            queryItemsDict[item.name] = item.value
        }

        if let error = queryItemsDict["error"] {
            let authorizationError = OAuth2AuthorizationError(errorCode: error)
            activeHandler?(.error(authorizationError))
            return shouldHandleURL
        }

        guard let code = queryItemsDict["code"] else {
            activeHandler?(.error(OAuth2AuthorizationError.unknown))
            return shouldHandleURL
        }

        let state = queryItemsDict["state"]
        let response = OAuth2AuthorizationResponse(code: code, state: state)
        activeHandler?(.value(response))
        return shouldHandleURL
    }

    func register(handler: @escaping Result<OAuth2AuthorizationResponse>.Block) {
        activeHandler?(.error(OAuth2AuthorizationError.cancelled))
        activeHandler = handler
    }

    func cancel() {
        activeHandler?(.error(OAuth2AuthorizationError.cancelled))
        activeHandler = nil
    }

}

#endif
