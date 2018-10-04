//
//  OAuth2URLSessionClientFactory.swift
//  Conduit
//
//  Created by John Hammerlund on 8/2/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

class OAuth2URLSessionClientFactory {

    private struct TokenGrantRequestPipelineMiddleware: RequestPipelineMiddleware {
        var pipelineBehaviorOptions: RequestPipelineBehaviorOptions = .awaitsOutgoingCompletion

        func prepareForTransport(request: URLRequest, completion: @escaping (Result<URLRequest>) -> Void) {
            completion(.value(request))
        }
    }

    static func makeClient() -> URLSessionClientType {
        var client = Auth.sessionClient
        client.requestMiddleware.append(TokenGrantRequestPipelineMiddleware())
        return client
    }

}
