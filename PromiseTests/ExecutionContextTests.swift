//
//  ExecutionContextTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 1/12/17.
//
//

import XCTest

@testable import Promise

class ExecutionContextTests: XCTestCase {


    func testNonInvalidatedInvalidatableQueue() {

        weak var expectation = self.expectation(description: "An InvalidatableQueue that hasn't been invalidated should execute its block.")

        let invalidatableQueue = InvalidatableQueue()

        let promise = Promise(value: 5)
            .then(on: invalidatableQueue, { (_) -> Void in
                expectation?.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.value == 5)
        
    }

    func testInvalidatedInvalidatableQueue() {

        weak var expectation = self.expectation(description: "An InvalidatableQueue that hasn't been invalidated should execute its block.")

        let invalidatableQueue = InvalidatableQueue()

        let promise = Promise(value: 5)
            .then(on: invalidatableQueue, { (_) -> Void in
                XCTFail()
            })

        invalidatableQueue.invalidate()

        delay(0.1, block: {
            expectation?.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.isPending)
        
        
    }
}
