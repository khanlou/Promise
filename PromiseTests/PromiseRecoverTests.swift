//
//  PromiseRecoverTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
import Promise

class PromiseRecoverTests: XCTestCase {
    func testRecover() {
        weak var expectation = self.expectation(description: "`Promise.recover` should recover from errors.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                reject(SimpleError())
            }
        }).recover({ error in
            XCTAssert(error as? SimpleError == SimpleError())
            return Promise(work: { (fulfill, reject) in
                fulfill(5)
            })
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        guard let int = promise.value else { XCTFail(); return }
        XCTAssertEqual(int, 5)
        XCTAssert(promise.isFulfilled)
    }
    
    func testRecoverWithThrowingFunction() {
        weak var expectation = self.expectation(description: "`Promise.recover` should allow throwing functions")

        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                reject(SimpleError())
            }
        }).recover({ error in
            XCTAssert(error as? SimpleError == SimpleError())
            _ = try JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
            return Promise(work: { (fulfill, reject) in
                fulfill(5)
            })
        }).always({
            expectation?.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
        guard let int = promise.value else { XCTFail(); return }
        XCTAssertEqual(int, 5)
        XCTAssert(promise.isFulfilled)
    }

    func testRecoverWithThrowingFunctionError() {
        weak var expectation = self.expectation(description: "`Promise.recover` should trigger `catch` when an error is thrown")

        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                reject(SimpleError())
            }
        }).recover({ (error) -> Promise<Int> in
            let wrench = Wrench()
            try wrench.throw()

            return Promise(value: 2)
        }).catch({ error in
            let wrenchError = error as? WrenchError
            XCTAssertNotNil(wrenchError, "Caught error here should be from the thrown function in `recover`")
            expectation?.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isRejected)
    }

    func testRecoverInstant() {
        weak var expectation = self.expectation(description: "`Promise.recover` should recover if the initial promise is rejected.")
        
        let promise = Promise<Int>(error: SimpleError()).recover({ error in
            XCTAssert(error as? SimpleError == SimpleError())
            return Promise(work: { (fulfill, reject) in
                fulfill(5)
            })
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        guard let int = promise.value else { XCTFail(); return }
        XCTAssertEqual(int, 5)
        XCTAssert(promise.isFulfilled)
    }
    
    func testIgnoreRecover() {
        weak var expectation = self.expectation(description: "`Promise.recover` shouldn't recover if the initial promise is fulfilled.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                fulfill(2)
            }
        }).recover({ error in
            XCTAssert(error as? SimpleError == SimpleError())
            return Promise(work: { (fulfill, reject) in
                fulfill(5)
            })
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        guard let int = promise.value else { XCTFail(); return }
        XCTAssertEqual(int, 2)
        XCTAssert(promise.isFulfilled)
    }
    
    func testIgnoreRecoverInstant() {
        weak var expectation = self.expectation(description: "`Promise.recover` shouldn't recover if the initial promise is fulfilled.")
        
        let promise = Promise(value: 2).recover({ error in
            XCTAssert(error as? SimpleError == SimpleError())
            return Promise(work: { (fulfill, reject) in
                fulfill(5)
            })
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        guard let int = promise.value else { XCTFail(); return }
        XCTAssertEqual(int, 2)
        XCTAssert(promise.isFulfilled)
    }

    static let allTests = [
        ("testRecover", testRecover),
        ("testRecoverWithThrowingFunction", testRecoverWithThrowingFunction),
        ("testRecoverWithThrowingFunctionError", testRecoverWithThrowingFunctionError),
        ("testRecoverInstant", testRecoverInstant),
        ("testIgnoreRecover", testIgnoreRecover),
        ("testIgnoreRecoverInstant", testIgnoreRecoverInstant),
    ]
}
