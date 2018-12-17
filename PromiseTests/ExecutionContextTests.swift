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

    func testConcurrency() {
        (0..<5).forEach { _ in self.testThreads() }
    }
    
    func testThreads() {
        var then: DispatchTime!
        var always: DispatchTime!
        weak var expectation = self.expectation(description: "Threading is hard!")
        Promise(value: 1)
        .then(on: DispatchQueue.global(qos: .default), { value in
            return 2
        })
        .then(on: DispatchQueue.global(qos: .background)) { value -> Promise<Int> in
            return Promise<Int>(queue: .main) { s, f in
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    s(3)
                }
            }
        }
        .then(on: DispatchQueue.global(qos: .background)) { value in
            return 4
        }
        .then(on: DispatchQueue.global(qos: .utility), { value in
            then = DispatchTime.now()
        })
        .catch(on: DispatchQueue.global(qos: .default)) { err in
            // do nothing, won't fail
        }
        .then(on: DispatchQueue.global(qos: .default)) { value in
            always = DispatchTime.now()
            XCTAssert(then != nil)
            XCTAssert(always > then)
            expectation?.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

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
        ("testThreads", testThreads),
        ("testConcurrency", testConcurrency),
        ("testNonInvalidatedInvalidatableQueue", testNonInvalidatedInvalidatableQueue),
        ("testInvalidatedInvalidatableQueue", testInvalidatedInvalidatableQueue),
        ("testTapContinuesToFireInvalidatableQueue", testTapContinuesToFireInvalidatableQueue),
        ("testInvalidatableQueueSupportsNonMainQueues", testInvalidatableQueueSupportsNonMainQueues),
    ]
}
