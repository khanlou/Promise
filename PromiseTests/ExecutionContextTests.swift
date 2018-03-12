//
//  ExecutionContextTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 1/12/17.
//
//

import XCTest

import Promise
import Dispatch

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

        weak var expectation = self.expectation(description: "An InvalidatableQueue that has been invalidated shouldn't execute its block.")

        let invalidatableQueue = InvalidatableQueue()

        invalidatableQueue.invalidate()

        Promise(value: 5)
            .then(on: invalidatableQueue, { (_) -> Void in
                XCTFail()
            })


        delay(0.1, block: {
            expectation?.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)

    }

    func testTapContinuesToFireInvalidatableQueue() {

        weak var expectation = self.expectation(description: "A tapping `then` block on an invalidated queue shouldn't prevent future then blocks from firing.")

        let invalidatableQueue = InvalidatableQueue()
        invalidatableQueue.invalidate()

        Promise(value: 5)
            .then(on: invalidatableQueue, { (_) -> Void in
                if #available(iOS 10, *) {
                    dispatchPrecondition(condition: .onQueue(.main))
                }
                XCTFail()
            })
            .then({ _ in
                expectation?.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)

    }

    func testInvalidatableQueueSupportsNonMainQueues() {

        weak var expectation = self.expectation(description: "Invalidatable queues should support non-main queues.")

        let backgroundQueue = DispatchQueue(label: "testqueue")
        let invalidatableQueue = InvalidatableQueue(queue: backgroundQueue)

        Promise(value: 5)
            .then(on: invalidatableQueue, { (_) -> Void in
                if #available(iOS 10, *) {
                    dispatchPrecondition(condition: .notOnQueue(.main))
                }
            })
            .then({ _ in
                expectation?.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
        
    }


    static let allTests = [
        ("testNonInvalidatedInvalidatableQueue", testNonInvalidatedInvalidatableQueue),
        ("testInvalidatedInvalidatableQueue", testInvalidatedInvalidatableQueue),
        ("testTapContinuesToFireInvalidatableQueue", testTapContinuesToFireInvalidatableQueue),
        ("testInvalidatableQueueSupportsNonMainQueues", testInvalidatableQueueSupportsNonMainQueues),
    ]
}
