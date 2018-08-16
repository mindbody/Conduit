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
    ///   - response: The exchanged HTTP response
    ///   - data: The exchanged response data
    ///   - error: The exchanged error
    ///   - completion: Must be called once the middleware has completed processing
    func prepare(request: URLRequest, response: inout HTTPURLResponse?, data: inout Data?, error: inout Error?, completion: @escaping () -> Void)

}
