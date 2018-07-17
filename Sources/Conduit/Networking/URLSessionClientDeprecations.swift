//
//  URLSessionClientDeprecations.swift
//  Conduit
//
//  Created by John Hammerlund on 7/17/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

extension URLSessionClient {

    @available(*, deprecated, message: "Use requestMiddleware instead.")
    public var middleware: [RequestPipelineMiddleware] {
        get {
            return requestMiddleware
        }
        set {
            requestMiddleware = newValue
        }
    }

}
