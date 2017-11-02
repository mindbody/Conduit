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
        let sut = Result<Int>.error(TestError.otherError)
        if case .error(let err) = sut, let error = err as? TestError, case .otherError = error {
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
        let r = Result<Int>.error(TestError.otherError)
        let rNew = r.convert { return Int64($0) } // Conversion we don't care about.

        if case .error(let e) = rNew {
            if let e = e as? TestError {
                XCTAssertEqual(e, TestError.otherError)
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
        let r = Result<Int>.error(TestError.otherError)

        // Converts the underlying error to a different case, but leaves the value unchanged.
        let rNew = r.convert(errorConverter: { _ in
            return TestError.yetAnotherError
        }, valueConverter: { return $0 })

        if case .error(let e) = rNew {
            if let e = e as? TestError {
                XCTAssertEqual(e, TestError.yetAnotherError)
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
        XCTAssertNil(Result<Int>.error(TestError.otherError).value)
    }

    func testOptionalErrorGetter() {
        let error = Result<Int>.error(TestError.otherError).error
        XCTAssertNotNil(error)
        guard case .some(TestError.otherError) = error else {
            XCTFail("Unexpected error")
            return
        }
        XCTAssertNil(Result<Int>.value(1).error)
    }

    func testThrowingValueGetter() throws {
        XCTAssertEqual(try Result<Int>.value(1).valueOrThrow(), 1)
        XCTAssertThrowsError(try Result<Int>.error(TestError.otherError).valueOrThrow())
    }

    func testThrowingValueGetterWithVoid() {
        XCTAssertNoThrow(try Result<Void>.value(()).valueOrThrow())
    }

    func testThrowingValueGetterErrorType() throws {
        do {
            _ = try Result<Int>.error(TestError.otherError).valueOrThrow()
        }
        catch TestError.otherError {
            // Pass
        }
        catch {
            XCTFail("Unexpected error type")
        }
    }

}
