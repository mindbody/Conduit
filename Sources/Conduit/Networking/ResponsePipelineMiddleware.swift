//
//  ResponsePipelineMiddleware.swift
//  Conduit
//
//  Created by John Hammerlund on 6/19/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

public protocol ResponsePipelineMiddleware {

    func prepare(request: URLRequest, response: inout HTTPURLResponse?, data: inout Data?, error: inout Error?, completion: @escaping () -> Void)

}
