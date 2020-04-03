//
//  ResponsePipelineMiddleware.swift
//  Conduit
//
//  Created by John Hammerlund on 6/19/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

/// Intercepts and potentially transforms a response payload from a session exchange
public protocol ResponsePipelineMiddleware {

    /// Pipes the response payload either from the client or from the previous middleware component,
    /// depending on its position in the middleware queue.
    ///
    /// - Parameters:
    ///   - request: The original request
    ///   - taskResponse: The exchanged task response including HTTP response, response data, error, and request metrics
    ///   - completion: Must be called once the middleware has completed processing
    func prepare(request: URLRequest, taskResponse: inout TaskResponse, completion: @escaping () -> Void)

}
