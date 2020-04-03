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
    var data: Data?
    var response: HTTPURLResponse?
    var expectedContentLength: Int64?
    var error: Error?
    @available(iOS 10, *)
    lazy var metrics: URLSessionTaskMetrics? = nil
}
