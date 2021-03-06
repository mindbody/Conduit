//
//  ResultTests.swift
//  ConduitTests
//
//  Created by Eneko Alonso on 3/27/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class ResultTests: XCTestCase {

    func testResultShouldStoreAnInt() {
        let sut = Result.value(3)
        if case .value(let int) = sut {
            XCTAssertEqual(int, 3)
        }
        else {
            XCTFail("Expected .value(<Int>)")
        }
    }

    func testResultShouldBeAbleToStoreAnError() {
        let sut = Result<Int>.error(SomeError.someCase)
        if case .error(let err) = sut, let error = err as? SomeError, case .someCase = error {
            // Pass
        }
        else {
            XCTFail("Expected .error(.other(\"something wrong\")")
        }
    }

    func testResultShouldStoreVoid() {
        let sut = Result<Void>.value(())
        if case .value = sut {
            // Pass
        }
        else {
            XCTFail("Expected .value, got \(sut)")
        }
    }

    func testRewrappingAResultShouldAllowDifferentTypesWithoutChangingTheUnderlyingError() {
        let result = Result<Int>.error(MyError.errorOne)
        let rNew = result.convert { return Int64($0) } // Conversion we don't care about.

        if case .error(let error) = rNew {
            if let error = error as? MyError {
                XCTAssertEqual(error, MyError.errorOne)
            }
            else {
                XCTFail("Unexpected error type")
            }
        }
        else {
            XCTFail("Didn't get an error")
        }
    }

    func testShouldAllowRewrappingTheErrorWithADifferentError() {
        let result = Result<Int>.error(MyError.errorOne)

        // Converts the underlying error to a different case, but leaves the value unchanged.
        let rNew = result.convert(errorConverter: { _ in
            return MyError.errorTwo
        }, valueConverter: { return $0 })

        if case .error(let error) = rNew {
            if let error = error as? MyError {
                XCTAssertEqual(error, MyError.errorTwo)
            }
            else {
                XCTFail("Unexpected error type")
            }
        }
        else {
            XCTFail("Didn't get an error")
        }
    }

    func testOptionalValueGetter() {
        XCTAssertEqual(Result<Int>.value(1).value, 1)
        XCTAssertNil(Result<Int>.error(SomeError.someCase).value)
    }

    func testOptionalErrorGetter() {
        let error = Result<Int>.error(MyError.errorOne).error
        XCTAssertNotNil(error)
        guard case .some(MyError.errorOne) = error else {
            XCTFail("Unexpected error")
            return
        }
        XCTAssertNil(Result<Int>.value(1).error)
    }

    func testThrowingValueGetter() throws {
        XCTAssertEqual(try Result<Int>.value(1).valueOrThrow(), 1)
        XCTAssertThrowsError(try Result<Int>.error(SomeError.someCase).valueOrThrow())
    }

    func testThrowingValueGetterWithVoid() {
        XCTAssertNoThrow(try Result<Void>.value(()).valueOrThrow())
    }

    func testThrowingValueGetterErrorType() throws {
        do {
            _ = try Result<Int>.error(SomeError.someCase).valueOrThrow()
        }
        catch SomeError.someCase {
            // Pass
        }
        catch {
            XCTFail("Unexpected error type")
        }
    }

}

private enum SomeError: Error {
    case someCase
}

private enum MyError: Error, Equatable {
    case errorOne
    case errorTwo
}
