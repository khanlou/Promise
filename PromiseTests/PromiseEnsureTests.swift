//
//  PromiseEnsureTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 12/4/16.
//
//

import XCTest
import Promise

class PromiseEnsureTests: XCTestCase {

    func testEnsureRejects() {
        weak var expectation = self.expectation(description: "`Promise.ensure` should reject the promise if the test fails.")

        let promise = Promise(value: 2)
            .ensure({ value in value == 3 })
            .always({
                expectation?.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNotNil(promise.error)
    }

    func testEnsureSucceeds() {
        weak var expectation = self.expectation(description: "`Promise.ensure` should continue the promise if the test succeeds.")

        let promise = Promise(value: 3)
            .ensure({ value in value == 3 })
            .always({
                expectation?.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(promise.error)
        XCTAssertEqual(promise.value, 3)
    }

    func testEnsureOnlyCalledOnSucceess() {
        weak var expectation = self.expectation(description: "`Promise.ensure` should not be called if the promise has already failed.")

        let promise = Promise(error: SimpleError())
            .ensure({ XCTFail(); return true })
            .always({
                expectation?.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNotNil(promise.error)
    }

    static let allTests = [
        ("testEnsureRejects", testEnsureRejects),
        ("testEnsureSucceeds", testEnsureSucceeds),
        ("testEnsureOnlyCalledOnSucceess", testEnsureOnlyCalledOnSucceess),
    ]
}
