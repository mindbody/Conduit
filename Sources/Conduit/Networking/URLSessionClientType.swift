//
//  URLSessionClientType.swift
//  Conduit
//
//  Created by Eneko Alonso on 4/3/20.
//  Copyright © 2020 MINDBODY. All rights reserved.
//

import Foundation

/// A type that manages a session and queues URLRequest's
public protocol URLSessionClientType {

    /// Queues a request into the session pipeline, blocking until request completes or fails
    /// - Parameters:
    ///     - request: The URLRequest to be enqueued
    /// - Returns: Tuple containing data and response
    /// - Throws: Error, if any
    func begin(request: URLRequest) throws -> (data: Data?, response: HTTPURLResponse)

    /// Queues a request into the session pipeline
    /// - Parameters:
    ///     - request: The URLRequest to be enqueued
    ///     - completion: The response handler
    @discardableResult
    func begin(request: URLRequest, completion: @escaping SessionTaskCompletion) -> SessionTaskProxyType

    /// The middleware that all incoming requests should be piped through
    var requestMiddleware: [RequestPipelineMiddleware] { get set }

    var responseMiddleware: [ResponsePipelineMiddleware] { get set }
}
