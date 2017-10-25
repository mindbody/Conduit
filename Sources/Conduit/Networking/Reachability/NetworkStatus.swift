//
//  NetworkStatus.swift
//  Conduit
//
//  Created by John Hammerlund on 12/14/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

#if !os(watchOS)

import Foundation
import SystemConfiguration

/// Represents the reachable status of a network connection.
///
/// - reachableViaWiFi: The network is reachable through WLAN (WiFi/ethernet)
/// - reachableWithRequiredIntervention: The network is reachable with user intervention needed
/// (i.e. authentication required) before traffic exchange
/// - reachableViaWWAN: The network is reachable through WWAN (LTE/4G/3G)
/// - unreachable: The network is not reachable
public enum NetworkStatus {
    /// The network is reachable through WLAN (WiFi/ethernet)
    case reachableViaWLAN
    /// The network is reachable with user intervention needed
    case reachableWithRequiredIntervention
#if os(iOS)
    /// The network is reachable through WWAN (LTE/4G/3G)
    case reachableViaWWAN
#endif
    /// The network is not reachable
    case unreachable

    init(systemReachabilityFlags: SCNetworkReachabilityFlags) {
        guard systemReachabilityFlags.contains(.reachable) else {
            self = .unreachable
            return
        }

#if os(iOS)
        guard systemReachabilityFlags.contains(.isWWAN) == false else {
            self = .reachableViaWWAN
            return
        }
#endif

        var status: NetworkStatus = .unreachable

        if systemReachabilityFlags.contains(.connectionRequired) == false {
            // If the network is reachable, but no connection is required, then the connection
            // is not WWAN (and therefore must be WiFi/ethernet)
            status = .reachableViaWLAN
        }

        if systemReachabilityFlags.contains(.connectionOnDemand) ||
            systemReachabilityFlags.contains(.connectionOnTraffic) {

            if systemReachabilityFlags.contains(.interventionRequired) == false {
                // It's possible that the network is on-demand or will only initiate
                // on traffic exchange. In these cases, it's possible that a user
                // must first intervene/authenticate with the network before
                // further traffic exchange is allowed by the network

                status = .reachableViaWLAN
            }
            else {
                status = .reachableWithRequiredIntervention
            }

        }

        self = status
    }

    init(systemReachability: SCNetworkReachability) {
        var reachabilityFlags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(systemReachability, &reachabilityFlags)
        self.init(systemReachabilityFlags: reachabilityFlags)
    }

    /// If true, then the network is reachable without required user intervention
    public var reachable: Bool {
#if os(iOS)
        return self == .reachableViaWWAN || self == .reachableViaWLAN
#else
        return self == .reachableViaWLAN
#endif
    }
}

#endif
