//
//  PromiseKickoffTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 9/17/17.
//
//

import XCTest
@testable import Promise

class PromiseKickoffTests: XCTestCase {

    func testKickoff() {
        weak var expectation = self.expectation(description: "Kicking off should result in a valid value.")

        let promise = Promises
            .kickoff({
                return "kicked off!"
            })
            .always({
                expectation?.fulfill()
            })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.value == "kicked off!")

    }

    func testFailingKickoff() {
        weak var expectation = self.expectation(description: "Kicking off should result in a valid value.")

        let promise = Promises
            .kickoff({
                throw SimpleError()
            })
            .always({
                expectation?.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isRejected)
    }

    func testPromiseKickoff() {
        weak var expectation = self.expectation(description: "Kicking off should result in a valid value.")

        let promise = Promises
            .kickoff({
                Promises
                    .delay(0.1)
                    .then({ return 2 })
            })
            .always({
                expectation?.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isFulfilled)
        XCTAssertEqual(promise.value, 2)
    }

    static let allTests = [
        ("testKickoff", testKickoff),
        ("testFailingKickoff", testFailingKickoff),
        ("testPromiseKickoff", testPromiseKickoff),
    ]
}
