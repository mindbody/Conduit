//
//  DarwinNotificationCenter.swift
//  Conduit
//
//  Created by John Hammerlund on 6/12/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

class DarwinNotificationObserver {

    let notificationName: String
    let handler: (DarwinNotificationObserver) -> Void
    let queue: DispatchQueue

    init(notificationName: String, queue: DispatchQueue, handler: @escaping (DarwinNotificationObserver) -> Void) {
        self.notificationName = notificationName
        self.queue = queue
        self.handler = handler
    }

}

/// Utilizes Core OS (Darwin) notifications, which are delivered system-wide. These notifications cannot carry
/// payloads, and sensitive information should not be broadcasted through this system.
class DarwinNotificationCenter {

    /// A Darwin system notification
    struct Notification {
        let name: String

        init(_ name: String) {
            self.name = name
        }
    }

    static let `default` = DarwinNotificationCenter()
    private let notifierQueue = DispatchQueue(label: "com.mindbodyonline.Conduit.DarwinNotificationCenter", attributes: .concurrent)
    private var observerMap: [String: [DarwinNotificationObserver]] = [:]

    /// Registers a new observer for a given system notification
    ///
    /// - Parameters:
    ///   - notification: The notification to observe
    ///   - operationQueue: The queue where observations should be handled (defaults to a background queue)
    ///   - handler: Handles observations when they occur
    /// - Returns: A registered observer
    @discardableResult
    func registerObserver(notification: Notification, queue: DispatchQueue = .global(), handler: @escaping (DarwinNotificationObserver) -> Void)
        -> DarwinNotificationObserver {
        let notificationName = notification.name
        let observer = DarwinNotificationObserver(notificationName: notificationName, queue: queue, handler: handler)
        notifierQueue.async(flags: .barrier) {
            var observers = self.observerMap[notificationName] ?? []
            let existingKeys = self.observerMap.keys
            observers.append(observer)
            self.observerMap[notificationName] = observers
            if existingKeys.contains(notificationName) {
                return
            }

            let center = CFNotificationCenterGetDarwinNotifyCenter()
            /// This will fire on the main thread
            let callback: CFNotificationCallback = { center, observer, name, object, dictionary in
                guard let name = name else {
                    return
                }
                DarwinNotificationCenter.default.handleDarwinNotification(name: name.rawValue as String)
            }

            CFNotificationCenterAddObserver(center,
                                            nil,
                                            callback,
                                            notificationName as CFString,
                                            nil,
                                            .deliverImmediately)
        }
        return observer
    }

    /// Unregisters an observer
    ///
    /// - Parameter observer: The observer to unregister
    func unregister(observer: DarwinNotificationObserver) {
        notifierQueue.async(flags: .barrier) {
            guard var observers = self.observerMap[observer.notificationName] else {
                return
            }
            guard let index = observers.firstIndex(where: { $0 === observer }) else {
                return
            }

            observers.remove(at: index)
            self.observerMap[observer.notificationName] = observers

            if observers.isEmpty {
                let center = CFNotificationCenterGetDarwinNotifyCenter()
                CFNotificationCenterRemoveObserver(center,
                                                   nil,
                                                   CFNotificationName(observer.notificationName as CFString),
                                                   nil)
            }
        }
    }

    /// Broadcasts a system notification
    ///
    /// - Parameter notification: The notification to broadcast
    func post(notification: Notification) {
        notifierQueue.async(flags: .barrier) {
            let center = CFNotificationCenterGetDarwinNotifyCenter()
            CFNotificationCenterPostNotification(center, CFNotificationName(notification.name as CFString), nil, nil, true)
        }
    }

    private func handleDarwinNotification(name: String) {
        notifierQueue.sync(flags: .barrier) {
            guard let observers = self.observerMap[name] else {
                return
            }
            observers.forEach { observer in
                observer.queue.sync {
                    observer.handler(observer)
                }
            }
        }
    }

}
