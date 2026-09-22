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

    func testReregistrationAfterAllObserversUnregister() throws {
        // Reproduces the bug described in issue #177 item 1:
        // register → post → handler fires → unregister (all observers gone) → register → post → handler must fire.
        let notification = DarwinNotificationCenter.Notification(#function)
        let center = DarwinNotificationCenter()

        let firstExpectation = expectation(description: "first post delivered")
        let observer = center.registerObserver(notification: notification) { _ in
            firstExpectation.fulfill()
        }
        center.post(notification: notification)
        wait(for: [firstExpectation], timeout: 1)
        center.unregister(observer: observer)

        // After unregistering the last observer, the key must be removed so a new registerObserver
        // call re-adds the CF callback. Without the fix the second post is never delivered.
        let secondExpectation = expectation(description: "second post delivered after re-registration")
        center.registerObserver(notification: notification) { _ in
            secondExpectation.fulfill()
        }
        center.post(notification: notification)
        wait(for: [secondExpectation], timeout: 1)
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
