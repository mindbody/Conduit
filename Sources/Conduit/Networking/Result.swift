//
//  Result.swift
//  Conduit
//
//  Created by Matthew Holden on 8/3/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation

/// Represents a disjoint union of either a value<T> and an Error
/// This is similar to Scala's `Either` data type, and we can employ it
/// to work around Swift's limited support for error handling in
/// methods that return values via a closure.
///
/// _Example:_
///
///     struct WidgetRepository {
///         func widget(withID ID: String, completion: (Result<Widget>) -> ()) { ... }
///     }
///
///
/// Using `Result<T>`'s nested `Block` typealias, the "completion" parameter can be simplified:
///
///     struct WidgetRepository {
///         func widget(withID ID: String, completion: Result<Widget>.Block) { ... }
///     }
///
public enum Result<T> {

    /// Repository methods can simplify their signatures by using this typealias.
    public typealias Block = (Result<T>) -> Void

    case value(T)
    case error(Error)
}

// MARK: Optional getters

extension Result {

    /// Optional value getter, useful when error value is ignored by the application.
    ///
    ///     if let value = result.value {
    ///         // Do something
    ///     }
    ///     else {
    ///         presentAlert(message: "Operation failed. Please try again.")
    ///     }
    ///
    public var value: T? {
        guard case .value(let value) = self else {
            return nil
        }
        return value
    }

    /// Optional error getter, useful when value is `Void` or not used and we are just 
    /// checking for presence of an error.
    ///
    ///     if let error = result.error {
    ///         presentAlert(error: error)
    ///     }
    ///     else {
    ///         // Nothing to do with `Void` value
    ///     }
    ///
    public var error: Error? {
        guard case .error(let error) = self else {
            return nil
        }
        return error
    }

}

// MARK: Throwing getters

extension Result {

    /// Throwing value getter, useful to use on synchronous code. Will attempt to extract value.
    /// Throws error if no value is present.
    ///
    ///     do {
    ///         let value = try result.valueOrThrow()
    ///         // Do something with `value`
    ///     }
    ///     catch let error {
    ///         // Do something with `error`
    ///     }
    ///
    public func valueOrThrow() throws -> T {
        switch self {
        case .value(let value):
            return value
        case .error(let error):
            throw error
        }
    }

}

// MARK: Error conversion

extension Result {

    /// Converts the wrapped value (or error) to a different and instance of a different type, `TNew`
    ///
    /// - Parameters:
    ///   - valueConverter: Conversion function for the `value` case. 
    ///     Receives the underlying `.value(T)` as an argument. Returns: `TNew`.
    ///   - errorConverter: Convertion function for the `error` case. 
    ///     Receives the underlying .error(Error) as an argument. Returns a different Error.
    ///     This argument can be nil, in which case the original, wrapped, `Error` is unchanged.
    ///
    /// - Returns: Result<TNew>
    public func convert<TNew>(errorConverter: ((Error) -> Error)? = nil, valueConverter: (T) -> TNew) -> Result<TNew> {
        switch self {
        case .error(let e):
            guard let ec = errorConverter else {
                return .error(e)
            }
            return .error(ec(e))
        case .value(let v):
            return .value(valueConverter(v))
        }
    }

}
