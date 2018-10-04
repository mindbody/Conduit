//
//  RequestPipelineMiddleware.swift
//  Conduit
//
//  Created by John Hammerlund on 7/22/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Represents options specific to the behavior of the request pipeline
public struct RequestPipelineBehaviorOptions: OptionSet {

    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// No special behaviors defined
    public static let none = RequestPipelineBehaviorOptions(rawValue: 0)

    /// Notifies the client to complete all outgoing requests before proceeding
    public static let awaitsOutgoingCompletion = RequestPipelineBehaviorOptions(rawValue: 1 << 0)
}

/// Intercepts and potentially transforms a request from a session exchange
public protocol RequestPipelineMiddleware {

    /// Represents options specific to the behavior of the request pipeline. Does not need to be constant.
    var pipelineBehaviorOptions: RequestPipelineBehaviorOptions { get }

    /// Pipes the request either from the client or from the previous middleware component,
    /// depending on its position in the middleware queue.
    /// - Parameters:
    ///     - request: The piped request
    ///     - completion: A closure that pipes the middleware's transformed URLRequest, or an error if processing failed
    func prepareForTransport(request: URLRequest, completion: @escaping Result<URLRequest>.Block)

}
