//
//  PromiseRetryTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
import Promise

class PromiseRetryTests: XCTestCase {
    func testRetry() {
        weak var expectation = self.expectation(description: "`Promise.retry` should retry and eventually succeed.")
        
        var currentCount = 3
        let promise = Promises.retry(count: 3, delay: 0, generate: { () -> Promise<Int> in
            if currentCount == 1 {
                return Promise(value: 8)
            }
            currentCount -= 1
            return Promise(error: SimpleError())
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(promise.value, 8)
        XCTAssert(promise.isFulfilled)
    }
    
    func testRetryWithInstantSuccess() {
        weak var expectation = self.expectation(description: "`Promise.retry` should never retry if it succeeds immediately.")
        
        var currentCount = 1
        let promise = Promises.retry(count: 3, delay: 0, generate: { () -> Promise<Int> in
            if currentCount == 0 {
                XCTFail()
            }
            currentCount -= 1
            return Promise(value: 8)
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(promise.value, 8)
        XCTAssert(promise.isFulfilled)
    }
    
    func testRetryWithNeverSuccess() {
        weak var expectation = self.expectation(description: "`Promise.retry` should never retry if it succeeds immediately.")
        
        let promise = Promises.retry(count: 3, delay: 0, generate: { () -> Promise<Int> in
            return Promise(error: SimpleError())
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isRejected)
    }

    static let allTests = [
        ("testRetry", testRetry),
        ("testRetryWithInstantSuccess", testRetryWithInstantSuccess),
        ("testRetryWithNeverSuccess", testRetryWithNeverSuccess),
    ]
}
