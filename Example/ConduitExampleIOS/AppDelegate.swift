//
//  AppDelegate.swift
//  ConduitExample
//
//  Created by John Hammerlund on 6/23/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import UIKit
import Conduit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        ConduitConfig.logger.level = .verbose

        return true
    }

}

