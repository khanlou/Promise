//
//  PromiseAlwaysTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
import Promise

class PromiseAlwaysTests: XCTestCase {
    
    func testAlways() {
        weak var expectation = self.expectation(description: "`Promise.always` should always fire when the promise is fulfilled.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.5) {
                fulfill(5)
            }
        })
        
        promise.always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isFulfilled)
    }
    
    func testAlwaysRejects() {
        weak var expectation = self.expectation(description: "`Promise.always` should always fire when the promise is rejected.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.5) {
                reject(SimpleError())
            }
        })
        
        promise.always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isRejected)
    }
    
    func testAlwaysInstantFulfill() {
        weak var expectation = self.expectation(description: "`Promise.always` should always fire when the promise is rejected.")
        
        let promise = Promise(value: 5)
        
        promise.always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isFulfilled)
    }
    
    func testAlwaysInstantReject() {
        weak var expectation = self.expectation(description: "`Promise.always` should always fire when the promise is rejected.")
        
        let promise = Promise<Int>(error: SimpleError())
        
        promise.always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isRejected)
    }


    static let allTests = [
        ("testAlways", testAlways),
        ("testAlwaysRejects", testAlwaysRejects),
        ("testAlwaysInstantFulfill", testAlwaysInstantFulfill),
        ("testAlwaysInstantReject", testAlwaysInstantReject),
    ]
}
