//
//  ConduitLogger.swift
//  Conduit
//
//  Created by John Hammerlund on 7/6/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Defines the 'severity' of a log message
public enum LogLevel: Int {
    case verbose
    case debug
    case info
    case warn
    case error
    case none
}

public protocol ConduitLoggerType {
    var level: LogLevel { get set }
    func log(_ block: @autoclosure () -> Any, level: LogLevel, function: String, filePath: String, line: Int)
}

extension ConduitLoggerType {
    func verbose(_ block: @autoclosure () -> Any, function: String = #function, filePath: String = #file, line: Int = #line) {
        log(block, level: .verbose, function: function, filePath: filePath, line: line)
    }

    func debug(_ block: @autoclosure () -> Any, function: String = #function, filePath: String = #file, line: Int = #line) {
        log(block, level: .debug, function: function, filePath: filePath, line: line)
    }

    func info(_ block: @autoclosure () -> Any, function: String = #function, filePath: String = #file, line: Int = #line) {
        log(block, level: .info, function: function, filePath: filePath, line: line)
    }

    func warn(_ block: @autoclosure () -> Any, function: String = #function, filePath: String = #file, line: Int = #line) {
        log(block, level: .warn, function: function, filePath: filePath, line: line)
    }

    func error(_ block: @autoclosure () -> Any, function: String = #function, filePath: String = #file, line: Int = #line) {
        log(block, level: .error, function: function, filePath: filePath, line: line)
    }
}

class ConduitLogger: ConduitLoggerType {
    var level: LogLevel = .error

    func log(_ block: @autoclosure () -> Any, level: LogLevel, function: String, filePath: String, line: Int) {
        if self.level.rawValue <= level.rawValue {
            print("[Conduit] \(block())")
        }
    }
}
