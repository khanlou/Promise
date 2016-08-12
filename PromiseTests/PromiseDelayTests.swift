//
//  PromiseDelayTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
@testable import Promise

class PromiseDelayTests: XCTestCase {
    func testDelay() {
        weak var expectation = expectationWithDescription("`Promise.delay` should succeed after the given time period has elapsed.")
        
        let goodPromise = Promise<()>.delay(0.2)
        let badPromise = Promise<()>.delay(1.1)
        XCTAssert(goodPromise.isPending)
        XCTAssert(badPromise.isPending)
        
        goodPromise.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssert(goodPromise.isFulfilled)
        XCTAssert(badPromise.isPending)
    }
    
    func testTimeoutPromise() {
        weak var expectation = expectationWithDescription("`Promise.timeout` should succeed after the given time period has elapsed.")
        
        let goodPromise = Promise<()>.timeout(0.2)
        let badPromise = Promise<()>.timeout(1.1)
        XCTAssert(goodPromise.isPending)
        XCTAssert(badPromise.isPending)
        
        goodPromise.onFailure({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssert(goodPromise.isRejected)
        XCTAssert(badPromise.isPending)
    }
}
