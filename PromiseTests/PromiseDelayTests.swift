//
//  PromiseDelayTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
import Promise

class PromiseDelayTests: XCTestCase {
    func testDelay() {
        weak var expectation = self.expectation(description: "`Promise.delay` should succeed after the given time period has elapsed.")
        
        let goodPromise = Promises.delay(0.2)
        let badPromise = Promises.delay(1.1)
        XCTAssert(goodPromise.isPending)
        XCTAssert(badPromise.isPending)
        
        goodPromise.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(goodPromise.isFulfilled)
        XCTAssert(badPromise.isPending)
    }
    
    func testTimeoutPromise() {
        weak var expectation = self.expectation(description: "`Promise.timeout` should succeed after the given time period has elapsed.")
        
        let goodPromise: Promise<()> = Promises.timeout(0.2)
        let badPromise: Promise<()> = Promises.timeout(1.1)
        XCTAssert(goodPromise.isPending)
        XCTAssert(badPromise.isPending)
        
        goodPromise.catch({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(goodPromise.isRejected)
        XCTAssert(badPromise.isPending)
    }
    
    func testTimeoutFunctionSucceeds() {
        weak var expectation = self.expectation(description: "`Promise.timeout` should succeed after the given time period has elapsed.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.01) {
                fulfill(5)
            }
        }).addTimeout(1)
        
        XCTAssert(promise.isPending)
        
        promise.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isFulfilled)
    }

    
    func testTimeoutFunctionFails() {
        weak var expectation = self.expectation(description: "`Promise.timeout` should succeed after the given time period has elapsed.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(1) {
                fulfill(5)
            }
        }).addTimeout(0.5)
        
        XCTAssert(promise.isPending)
        
        promise.catch({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isRejected)
    }

    static let allTests = [
        ("testDelay", testDelay),
        ("testTimeoutPromise", testTimeoutPromise),
        ("testTimeoutFunctionSucceeds", testTimeoutFunctionSucceeds),
        ("testTimeoutFunctionFails", testTimeoutFunctionFails),
    ]
}
