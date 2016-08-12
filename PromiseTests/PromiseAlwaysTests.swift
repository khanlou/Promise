//
//  PromiseAlwaysTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
@testable import Promise

class PromiseAlwaysTests: XCTestCase {
    
    func testAlways() {
        weak var expectation = expectationWithDescription("`Promise.always` should always fire when the promise is fulfilled.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.5) {
                fulfill(5)
            }
        })
        
        promise.always({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssert(promise.isFulfilled)
    }
    
    func testAlwaysRejects() {
        weak var expectation = expectationWithDescription("`Promise.always` should always fire when the promise is rejected.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.5) {
                reject(SimpleError())
            }
        })
        
        promise.always({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssert(promise.isRejected)
    }
    
    func testAlwaysInstantFulfill() {
        weak var expectation = expectationWithDescription("`Promise.always` should always fire when the promise is rejected.")
        
        let promise = Promise(value: 5)
        
        promise.always({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssert(promise.isFulfilled)
    }
    
    func testAlwaysInstantReject() {
        weak var expectation = expectationWithDescription("`Promise.always` should always fire when the promise is rejected.")
        
        let promise = Promise<Int>(error: SimpleError())
        
        promise.always({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssert(promise.isRejected)
    }

}
