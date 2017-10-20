//
//  ConduitLogger.swift
//  Conduit
//
//  Created by John Hammerlund on 7/6/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Defines the 'severity' of a log message
/// - Note: A higher log level verbosity will capture all logs within lower
/// levels, i.e. LogLevel.info will capture .info, .warn, and .error logs
public enum LogLevel: Int {
    /// Verbose debug logs
    case verbose
    /// Nonverbose debug logs
    case debug
    /// Informational progress logs
    case info
    /// Warning / potential harm logs
    case warn
    /// Error logs
    case error
    /// Ignores all logs
    case noOutput
}

extension LogLevel: Comparable {

    public static func == (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }

    public static func <= (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }

    public static func >= (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }

    public static func > (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

}

/// Handles incoming log messages from all of Conduit
public protocol ConduitLoggerType {
    /// The severity of log messages received
    var level: LogLevel { get set }

    /// Handles an incoming log message
    /// - Parameters:
    ///   - block: The log generator
    ///   - function: The name of the function from which the log originates
    ///   - filePath: The name of the source file from which the log originates
    ///   - line: The line number in which the log originates
    func log(_ block: @autoclosure () -> Any, function: String, filePath: String, line: Int)
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

    func log(_ block: @autoclosure () -> Any, level: LogLevel, function: String, filePath: String, line: Int) {
        if level.rawValue <= level.rawValue {
            log(block, function: function, filePath: filePath, line: line)
        }
    }
}

class ConduitLogger: ConduitLoggerType {
    var level: LogLevel = .error

    func log(_ block: @autoclosure () -> Any, function: String, filePath: String, line: Int) {
        if level.rawValue <= level.rawValue {
            print("[Conduit] \(block())")
        }
    }
}
