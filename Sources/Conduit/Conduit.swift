//
//  Conduit.swift
//  Conduit
//
//  Created by John Hammerlund on 7/12/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Global (framework-wide) logger.
/// It offered as a global variable to allow the natural-looking call-site syntax:
/// logger.debug("blah blah")
internal var logger: ConduitLoggerType = {
    return ConduitConfig.logger
}()

/// A static configuration object for Conduit
public final class ConduitConfig {

    static public var logger: ConduitLoggerType = ConduitLogger()

}
