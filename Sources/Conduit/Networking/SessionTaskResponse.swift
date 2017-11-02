//
//  SessionTaskResponse.swift
//  Conduit
//
//  Created by Eneko Alonso on 11/2/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Session task response contains all elements from a network task request.
public struct SessionTaskResponse {
    var request: URLRequest?
    var response: HTTPURLResponse?
    var data: Data?
    var error: Error?

    init(request: URLRequest? = nil, response: HTTPURLResponse? = nil, data: Data? = nil, error: Error? = nil) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
    }
}
