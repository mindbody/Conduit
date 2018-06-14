//
//  DarwinNotificationCenterTests.swift
//  Conduit
//
//  Created by John Hammerlund on 6/13/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class DarwinNotificationCenterTests: XCTestCase {

    func testNotifiesRegisteredObservers() throws {
        let notification = DarwinNotificationCenter.Notification(#function)

        let numNotificationsToSend = 2
        let numObservers = 20
        let notificationsHandledExpectation = expectation(description: "all notifications handled")
        notificationsHandledExpectation.expectedFulfillmentCount = numNotificationsToSend * numObservers

        for _ in 0..<numObservers {
            DarwinNotificationCenter.default.registerObserver(notification: notification) { _ in
                notificationsHandledExpectation.fulfill()
            }
        }

        for _ in 0..<numNotificationsToSend {
            DarwinNotificationCenter.default.post(notification: notification)
        }

        waitForExpectations(timeout: 1)
    }

    func testDoesntNotifyUnregisteredObservers() throws {
        let notification = DarwinNotificationCenter.Notification(#function)

        let numNotificationsToSend = 2
        let numObservers = 20
        let notificationsHandledExpectation = expectation(description: "all notifications handled")
        notificationsHandledExpectation.expectedFulfillmentCount = numObservers

        for _ in 0..<numObservers {
            DarwinNotificationCenter.default.registerObserver(notification: notification) { observer in
                DarwinNotificationCenter.default.unregister(observer: observer)
                notificationsHandledExpectation.fulfill()
            }
        }

        for _ in 0..<numNotificationsToSend {
            DarwinNotificationCenter.default.post(notification: notification)
        }

        waitForExpectations(timeout: 1)
    }

}
