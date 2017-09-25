//
//  NetworkReachability.swift
//  Conduit
//
//  Created by John Hammerlund on 12/14/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//
#if !os(watchOS)

import Foundation
import SystemConfiguration

/// A handler that fires on any change in network reachability
public typealias NetworkReachabilityChangeHandler = (NetworkReachability) -> Void

/// Represents the reachability of a specific network connection, or all network connections.
public class NetworkReachability {

    /// Network reachabillity across all connections
    public static var internet: NetworkReachability = {
        let sockAddrInSize = UInt8(MemoryLayout<sockaddr>.size)
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = sockAddrInSize
        zeroAddress.sa_family = UInt8(AF_INET)
        guard let reachability = NetworkReachability(socketAddress: zeroAddress) else {
            preconditionFailure("Could not initialize reachability")
        }
        return reachability
    }()

    private let systemReachability: SCNetworkReachability
    private(set) var observers = [NetworkReachabilityObserver]()
    private(set) var isPollingReachability = false

    /// The current reachable status of the network connection
    public private(set) var status: NetworkStatus

    /// Attempts to produce a NetworkReachability against a given host
    ///
    /// - Parameter hostName: The host to connect to (i.e. mindbodyonline.com)
    public convenience init?(hostName: String) {
        guard let data = hostName.data(using: .utf8) else {
            return nil
        }
        var reachability: SCNetworkReachability?
        data.withUnsafeBytes { (ptr: UnsafePointer<Int8>) in
            reachability = SCNetworkReachabilityCreateWithName(nil, ptr)
        }
        guard let systemReachability = reachability else {
            return nil
        }

        self.init(systemReachability: systemReachability)
    }

    private convenience init?(socketAddress: sockaddr) {
        var socketAddress = socketAddress
        let pointer: (UnsafePointer<sockaddr>) -> SCNetworkReachability? = {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        if let systemReachability: SCNetworkReachability = withUnsafePointer(to: &socketAddress, pointer) {
            self.init(systemReachability: systemReachability)
        }
        else {
            return nil
        }
    }

    private init(systemReachability: SCNetworkReachability) {
        self.systemReachability = systemReachability
        self.status = NetworkStatus(systemReachability: systemReachability)
        configureReachabilityCallback()
        startPollingReachability()
    }

    private func configureReachabilityCallback() {
        /// SCNetworkReachabilitySetCallback requires a function pointer,
        /// which means the closure is effectively global, static memory.
        /// Because of this, the registered callback cannot capture anything,
        /// and any outside context must be passed through "info", which is a pointer to opaque memory.
        let unmanagedSelf = Unmanaged<NetworkReachability>.passUnretained(self).toOpaque()
        var context = SCNetworkReachabilityContext(version: 0,
                                                   info: UnsafeMutableRawPointer(unmanagedSelf),
                                                   retain: nil,
                                                   release: nil,
                                                   copyDescription: nil)
        SCNetworkReachabilitySetCallback(self.systemReachability, { (_, reachabilityFlags, info) in
            guard let info = info else {
                return
            }

            let networkStatus = NetworkStatus(systemReachabilityFlags: reachabilityFlags)

            let networkReachability = Unmanaged<NetworkReachability>.fromOpaque(info).takeUnretainedValue()
            networkReachability.status = networkStatus
            for observer in networkReachability.observers {
                observer.handler(networkReachability)
            }
        }, &context)
    }

    /// Registers a closure to be fired every time reachability changes
    ///
    /// - Parameter handler: The handler to register
    /// - Returns: An observer that can be unregistered if needed
    @discardableResult
    public func register(handler: @escaping NetworkReachabilityChangeHandler) -> NetworkReachabilityObserver {
        let observer = NetworkReachabilityObserver(handler)
        observers.append(observer)
        return observer
    }

    /// Unregisters a network reachability observer
    ///
    /// - Parameter observer: The observer to unregister
    public func unregister(observer: NetworkReachabilityObserver) {
        if let idx = self.observers.index(where: { $0 === observer }) {
            observers.remove(at: idx)
        }
    }

    /// Unregisters all network reachability observers
    public func unregisterAllObservers() {
        observers = []
    }

    private func startPollingReachability() {
        if !isPollingReachability {
            isPollingReachability = SCNetworkReachabilityScheduleWithRunLoop(systemReachability,
                                                                             RunLoop.current.getCFRunLoop(),
                                                                             RunLoopMode.defaultRunLoopMode as CFString)
        }
    }

    deinit {
        SCNetworkReachabilitySetCallback(systemReachability, nil, nil)
    }

}

/// Responds to network reachability changes based on a reachability configuration
public class NetworkReachabilityObserver {

    let handler: NetworkReachabilityChangeHandler

    init(_ handler: @escaping NetworkReachabilityChangeHandler) {
        self.handler = handler
    }
}

#endif
