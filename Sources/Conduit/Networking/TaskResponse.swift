//
//  TaskResponse.swift
//  Conduit
//
//  Created by Eneko Alonso on 4/3/20.
//  Copyright © 2020 MINDBODY. All rights reserved.
//

import Foundation

/// Encapsulate received data, HTTP response, error, and metrics, where available
public struct TaskResponse {
    public var data: Data?
    public var response: HTTPURLResponse?
    public var error: Error?

    @available(iOS 10, *)
    public lazy var metrics: URLSessionTaskMetrics? = nil

    var expectedContentLength: Int64?

    public init() {}
}
