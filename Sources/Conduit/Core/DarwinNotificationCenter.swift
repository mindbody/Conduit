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

    init(notificationName: String, handler: @escaping (DarwinNotificationObserver) -> Void) {
        self.notificationName = notificationName
        self.handler = handler
    }

}

class DarwinNotificationCenter {

    struct Notification {
        let name: String

        init(_ name: String) {
            self.name = name
        }
    }

    static let `default` = DarwinNotificationCenter()
    private let serialQueue = DispatchQueue(label: "com.mindbodyonline.Conduit.DarwinNotificationCenter")
    private var observerMap: [String: [DarwinNotificationObserver]] = [:]

    @discardableResult
    func registerObserver(notification: Notification, handler: @escaping (DarwinNotificationObserver) -> Void) -> DarwinNotificationObserver {
        let notificationName = notification.name
        let observer = DarwinNotificationObserver(notificationName: notificationName, handler: handler)
        serialQueue.async {
            var observers = self.observerMap[notificationName] ?? []
            let existingKeys = self.observerMap.keys
            observers.append(observer)
            self.observerMap[notificationName] = observers
            if existingKeys.contains(notificationName) {
                return
            }

            let center = CFNotificationCenterGetDarwinNotifyCenter()
            let selfPtr = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
            let callback: CFNotificationCallback = { center, observer, name, object, dictionary in
                guard let observer = observer, let name = name else {
                    return
                }
                let unretainedSelf = Unmanaged<DarwinNotificationCenter>.fromOpaque(observer).takeRetainedValue()
                unretainedSelf.handleDarwinNotification(name: name.rawValue as String)
            }

            CFNotificationCenterAddObserver(center,
                                            selfPtr,
                                            callback,
                                            notificationName as CFString,
                                            nil,
                                            .deliverImmediately)
        }
        return observer
    }

    func unregister(observer: DarwinNotificationObserver) {
        serialQueue.async {
            guard var observers = self.observerMap[observer.notificationName] else {
                return
            }
            guard let index = observers.index(where: { $0 === observer }) else {
                return
            }

            observers.remove(at: index)
            self.observerMap[observer.notificationName] = observers

            if observers.isEmpty {
                let center = CFNotificationCenterGetDarwinNotifyCenter()
                let selfPtr = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
                CFNotificationCenterRemoveObserver(center,
                                                   selfPtr,
                                                   CFNotificationName(observer.notificationName as CFString),
                                                   nil)
            }
        }
    }

    func post(notification: Notification) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(notification.name as CFString), nil, nil, true)
    }

    private func handleDarwinNotification(name: String) {
        serialQueue.async {
            guard let observers = self.observerMap[name] else {
                return
            }
            observers.forEach {
                $0.handler($0)
            }
        }
    }

}
