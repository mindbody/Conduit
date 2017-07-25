//
//  AwaitNetworkConnectivityRequestPipelineMiddleware.swift
//  Conduit
//
//  Created by John Hammerlund on 4/24/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//
#if !os(Linux) && !os(watchOS)
import Foundation

/// A middleware component for use within a URLSessionClient pipeline that halts pipeline
/// execution while the network is unreachable.
public struct AwaitNetworkConnectivityRequestPipelineMiddleware: RequestPipelineMiddleware {

    public var pipelineBehaviorOptions: RequestPipelineBehaviorOptions = []

    private let timeout: TimeInterval?

    /// Creates a new AwaitNetworkConnectivityRequestPipelineMiddleware with a provided
    /// timeout interval for awaiting an internet connection. If nil, then
    /// the application will continue to wait until the network is reachable.
    public init(timeout: TimeInterval? = nil) {
        self.timeout = timeout
    }

    public func prepareForTransport(request: URLRequest, completion: @escaping ((Result<URLRequest>) -> Void)) {
        let reachabilityStatus = NetworkReachability.internet.status
        if reachabilityStatus.reachable {
            completion(.value(request))
            return
        }
        weak var observer: NetworkReachabilityObserver?
        observer = NetworkReachability.internet.register { reachability in
            if reachability.status.reachable {
                guard let observer = observer else {
                    return
                }
                NetworkReachability.internet.unregister(observer: observer)
                completion(.value(request))
            }
        }

        if let timeout = timeout {
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                guard let observer = observer else {
                    return
                }
                NetworkReachability.internet.unregister(observer: observer)
                completion(.value(request))
            }
        }
    }

}

#endif
