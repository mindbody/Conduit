//
//  OAuth2SafariAuthorizationStrategy.swift
//  Conduit
//
//  Created by John Hammerlund on 6/28/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
import SafariServices

/// Directs a potential resource owner to a web-based authorization request in an SFSafariViewController
@available(iOS 9, *)
public class OAuth2SafariAuthorizationStrategy: NSObject, OAuth2AuthorizationStrategy {

    private let presentingViewController: UIViewController
    private let authorizationRequestEndpoint: URL

    /// The redirect handler used for authorization responses via a custom URL scheme
    public var redirectHandler: OAuth2AuthorizationRedirectHandler = .default

    /// Creates a new OAuth2SafariAuthorizationStrategy
    /// - Parameters:
    ///   - presentingViewController: The view controller from which to present the SFSafariViewController with an authorization request
    ///   - authorizationRequestEndpoint: The unformatted endpoint at which authorization requests are sent
    public init(presentingViewController: UIViewController, authorizationRequestEndpoint: URL) {
        self.presentingViewController = presentingViewController
        self.authorizationRequestEndpoint = authorizationRequestEndpoint
        super.init()
    }

    public func authorize(request: OAuth2AuthorizationRequest, completion: @escaping Result<OAuth2AuthorizationResponse>.Block) {
        let requestURL = makeAuthorizationRequestURL(request: request)

        logger.debug("Attempting authorization at URL: \(requestURL)")

        DispatchQueue.main.async {
            let safariViewController = SFSafariViewController(url: requestURL)
            safariViewController.delegate = self
            self.presentingViewController.present(safariViewController, animated: true, completion: nil)

            self.redirectHandler.register { result in
                DispatchQueue.main.async {
                    safariViewController.dismiss(animated: true, completion: nil)
                    completion(result)
                }
            }
        }
    }

    private func makeAuthorizationRequestURL(request: OAuth2AuthorizationRequest) -> URL {
        let requestBuilder = HTTPRequestBuilder(url: authorizationRequestEndpoint)

        var parameters = request.additionalParameters ?? [:]
        parameters["client_id"] = request.clientIdentifier
        parameters["response_type"] = "code"
        parameters["redirect_uri"] = request.redirectURI?.absoluteString
        parameters["scope"] = request.scope
        parameters["state"] = request.state

        requestBuilder.queryStringParameters = parameters

        guard let request = try? requestBuilder.build() else {
            return authorizationRequestEndpoint
        }
        return request.url ?? authorizationRequestEndpoint
    }

}

@available(iOS 9, *)
extension OAuth2SafariAuthorizationStrategy: SFSafariViewControllerDelegate {

    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        redirectHandler.cancel()
    }

}
