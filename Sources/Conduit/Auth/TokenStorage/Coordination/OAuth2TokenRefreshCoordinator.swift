//
//  OAuth2TokenRefreshCoordinator.swift
//  Conduit
//
//  Created by John Hammerlund on 6/12/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

/// Coordinates token refreshes across multiple sessions active within different processes, such as app extensions
class OAuth2TokenRefreshCoordinator {

    static let shared = OAuth2TokenRefreshCoordinator()

    /// Waits for a system token refresh completion notification
    ///
    /// - Parameters:
    ///   - timeout: The maximum amount of time to wait for the signal before executing the handler
    ///   - handler: Handles the notification observation, or the timeout being reached
    func waitForRefresh(timeout: TimeInterval, handler: @escaping () -> Void) {
        var workItem: DispatchWorkItem?
        let observer = DarwinNotificationCenter.default.registerObserver(notification: .didEndTokenFetchNotification) { observer in
            workItem?.cancel()
            DarwinNotificationCenter.default.unregister(observer: observer)
            handler()
        }

        let work = DispatchWorkItem {
            DarwinNotificationCenter.default.unregister(observer: observer)
            handler()
        }
        workItem = work

        observer.queue.asyncAfter(deadline: .now() + timeout, execute: work)
    }

    /// Fires a system notification that a token refresh has started
    func beginTokenRefresh() {
        DarwinNotificationCenter.default.post(notification: .didBeginTokenFetchNotification)
    }

    /// Fires a system notification that a token refresh has ended
    func endTokenRefresh() {
        DarwinNotificationCenter.default.post(notification: .didEndTokenFetchNotification)
    }
}

extension DarwinNotificationCenter.Notification {

    static let didBeginTokenFetchNotification = DarwinNotificationCenter.Notification("com.mindbodyonline.Conduit.oauth2-token-fetch.start")
    static let didEndTokenFetchNotification = DarwinNotificationCenter.Notification("com.mindbodyonline.Conduit.oauth2-token-end")

}
