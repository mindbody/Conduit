//
//  OAuth2TokenRefreshCoordinator.swift
//  Conduit
//
//  Created by John Hammerlund on 6/12/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

//public protocol OAuth2TokenRefreshCoordinationPersistence {
//    var state: OAuth2TokenRefreshCoordinator.State { get set }
//}

public class OAuth2TokenRefreshCoordinator {

//    public enum State: String {
//        case refreshing
//        case open
//    }

//    private var relinquishTimeout: TimeInterval = 30
//    private let clientIdentifier: String
//    private var statePersistence: OAuth2TokenRefreshCoordinationPersistence!
//    var state: State {
//        get {
//            return statePersistence.state
//        }
//        set {
//            statePersistence.state = newValue
//        }
//    }
//
//    init(clientIdentifier: String) {
//        self.clientIdentifier = clientIdentifier
//    }

    static let shared = OAuth2TokenRefreshCoordinator()

    func waitForRefresh(handler: @escaping () -> Void) {
        DarwinNotificationCenter.default.registerObserver(notification: .didEndTokenFetchNotification) { observer in
            DarwinNotificationCenter.default.unregister(observer: observer)
            handler()
        }
    }

    func beginTokenRefresh() {
        DarwinNotificationCenter.default.post(notification: .didBeginTokenFetchNotification)
    }

    func endTokenRefresh() {
        DarwinNotificationCenter.default.post(notification: .didEndTokenFetchNotification)
    }

//    func coordinatingTokenAccess(clientIdentifier: String, authorizationLevel: String) {
//        DarwinNotificationCenter.default.registerObserver(name: .didBeginTokenFetchNotificationName(clientIdentifier: clientIdentifier, authorizationLevel: authorizationLevel)) { _ in
//
//        }
//    }

}

extension DarwinNotificationCenter.Notification {

    static let didBeginTokenFetchNotification = DarwinNotificationCenter.Notification("com.mindbodyonline.Conduit.oauth2-token-fetch.start")
    static let didEndTokenFetchNotification = DarwinNotificationCenter.Notification("com.mindbodyonline.Conduit.oauth2-token-end")
}
