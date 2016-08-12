//
//  PromiseRetryTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
@testable import Promise

class PromiseRetryTests: XCTestCase {
    func testRetry() {
        weak var expectation = expectationWithDescription("`Promise.retry` should retry and eventually succeed.")
        
        var currentCount = 3
        let promise = Promise<Int>.retry(count: 3, delay: 0, generate: { () -> Promise<Int> in
            if currentCount == 1 {
                return Promise(value: 8)
            }
            currentCount -= 1
            return Promise(error: SimpleError())
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertEqual(promise.value, 8)
        XCTAssert(promise.isFulfilled)
    }
}
