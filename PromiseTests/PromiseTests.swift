//
//  PromiseTests.swift
//  PromiseTests
//
//  Created by Soroush Khanlou on 8/1/16.
//
//

import XCTest
@testable import Promise

private func delay(duration: NSTimeInterval, block: () -> ()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(duration*Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), {
        block()
    })
}

class PromiseTests: XCTestCase {
    func testThen() {
        
        weak var expectation = expectationWithDescription("The then function should be called twice.")
        var count = 0
        
        let promise = Promise(value: 5).then({ _ in
            count += 1
        }).then({ _ in
            count += 1
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssert(count == 2)
        XCTAssert(promise.isFulfilled)
    }
    
    func testAsync() {
        weak var expectation = expectationWithDescription("The `work:` based constructor of Promise should work correctly.")
        Promise<String>(work: { (fulfill, reject) in
            delay(0.05) {
                fulfill("hey")
            }
        }).then({ string in
            XCTAssertEqual(string, "hey")
            expectation?.fulfill()
        })
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testAsyncRejection() {
        weak var expectation = expectationWithDescription("Calling `reject` from the `work:` constructor should cause the Promise to be rejceted.")
        let promise = Promise<String>(work: { (fulfill, reject) in
            delay(0.05) {
                reject(NSError(domain: "com.khanlou.pinky", code: 1, userInfo: nil))
            }
        }).then({ string in
            XCTFail()
        }).then({ string in
            XCTFail()
        }).then({ string in
            XCTFail()
        }).then({ string in
            XCTFail()
        }).onFailure({ error in
            expectation?.fulfill()
        })
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertNotNil(promise.error)
        XCTAssert(promise.isRejected)
    }
    
    func testThenWhenPending() {
        weak var expectation = expectationWithDescription("Pending Promises shouldn't call their `then` callbacks.")
        
        var thenCalled = false
        
        Promise().then({ (value: Int) -> Int in
            thenCalled = true
            return 2
        })
        delay(0.05) {
            expectation?.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertFalse(thenCalled)
    }
    
    func testRejectedAfterFulfilled() {
        weak var expectation = expectationWithDescription("A Promise that is rejected after being fulfilled should not call any further `then` callbacks.")
        
        var thenCalled = false
        
        let promise = Promise(value: 5).then({ _ in
            thenCalled = true
        })
        
        promise.then({ _ in
            XCTFail()
        })
        
        promise.reject(NSError(domain: "com.khanlou.pinky", code: 0, userInfo: nil))
        
        delay(0.05) {
            expectation?.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(thenCalled)
        XCTAssert(promise.isRejected)
    }
    
    func testPending() {
        let promise = Promise<Int>()
        
        XCTAssert(promise.isPending)
    }
    
    func testFulfilled() {
        weak var expectation = expectationWithDescription("A Promise that has `fulfill` called on it should be fulfilled with the value passed to `fullfill`.")
        
        let promise = Promise<Int>()
        
        promise.then({ value in
            XCTAssertEqual(value, 10)
        })
        
        promise.fulfill(10)
        
        delay(0.05) {
            expectation?.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(promise.value == 10)
        XCTAssert(promise.isFulfilled)
    }
    
    func testRejected() {
        weak var expectation = expectationWithDescription("A Promise that is rejected should have its `onFailure` method called.")
        
        let error = NSError(domain: "com.khanlou.pinky", code: 0, userInfo: nil)
        let promise = Promise<Int>()
        
        promise.onFailure({ _ in
            expectation?.fulfill()
        })
        
        promise.reject(error)
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertEqual(promise.error as? NSError, error)
        XCTAssert(promise.isRejected)
    }
    
    func testMap() {
        weak var expectation = expectationWithDescription("")
        
        let promise = Promise(value: "someString").then({ string in
            return string.characters.count
        }).then({ count in
            return count*2
        }).then({ doubled in
            XCTAssertEqual(doubled, 20)
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertEqual(promise.value, 20)
        XCTAssert(promise.isFulfilled)
    }
    
    func testFlatMap() {
        weak var expectation = expectationWithDescription("A `then` callback that returns another Promise should execute and fulfill the next Promise.")
        let promise = Promise<String>(work: { fulfill, reject in
            delay(0.05) {
                fulfill("hello")
            }
        }).then({ value in
            return Promise<Int>(work: { fulfill, reject in
                usleep(5000)
                fulfill(value.characters.count)
            })
        }).then({ value in
            XCTAssertEqual(value, 5)
            expectation?.fulfill()
        })
        
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertEqual(promise.value, 5)
        XCTAssert(promise.isFulfilled)
    }
    
    func testAll() {
        weak var expectation = expectationWithDescription("`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        let promise1 = Promise(value: 1)
        let promise2 = Promise<Int>(work: { fulfill, reject in
            delay(0.05) {
                fulfill(2)
            }
        })
        let promise3 = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                fulfill(3)
            }
        })
        let promise4 = Promise<Int>(work: { fulfill, reject in
            delay(0.09) {
                fulfill(4)
            }
        })
        
        let final = Promise<Int>.all([promise1, promise2, promise3, promise4])
        
        final.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        guard let array = final.value else { XCTFail(); return }
        XCTAssertEqual(array, [1, 2, 3, 4])
        XCTAssert(final.isFulfilled)
    }
    
    func testAllWithPreFulfilledValues() {
        weak var expectation = expectationWithDescription("`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        let promise1 = Promise(value: 1)
        let promise2 = Promise(value: 2)
        let promise3 = Promise(value: 3)
        
        let final = Promise<Int>.all([promise1, promise2, promise3])
        
        final.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        guard let array = final.value else { XCTFail(); return }
        XCTAssertEqual(array, [1, 2, 3])
        XCTAssert(final.isFulfilled)
    }
    
    func testAllWithRejectionHappeningFirst() {
        weak var expectation = expectationWithDescription("`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        let promise1 = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                fulfill(2)
            }
        })
        let promise2 = Promise<Int>(work: { fulfill, reject in
            delay(0.05) {
                reject(NSError(domain: "com.khanlou.pinky", code: 1, userInfo: nil))
            }
        })
        
        let final = Promise<Int>.all([promise1, promise2])
        
        final.then({ _ in
            XCTFail()
        })
        
        final.then({ _ in
            XCTFail()
        })
        
        final.onFailure({ _ in
            expectation?.fulfill()
        })
        
        final.then({ _ in
            XCTFail()
        })
        
        waitForExpectationsWithTimeout(10, handler: nil)
        XCTAssertNotNil(final.error)
        XCTAssert(final.isRejected)
    }
    
    func testAllWithRejectionHappeningLast() {
        weak var expectation = expectationWithDescription("`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        let promise1 = Promise<Int>(work: { fulfill, reject in
            delay(0.05) {
                fulfill(2)
            }
        })
        let promise2 = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                reject(NSError(domain: "com.khanlou.pinky", code: 1, userInfo: nil))
            }
        })
        
        let final = Promise<Int>.all([promise1, promise2])
        
        final.then({ _ in
            XCTFail()
        })
        
        final.then({ _ in
            XCTFail()
        })
        
        final.onFailure({ _ in
            expectation?.fulfill()
        })
        
        final.then({ _ in
            XCTFail()
        })
        
        waitForExpectationsWithTimeout(10, handler: nil)
        XCTAssertNotNil(final.error)
        XCTAssert(final.isRejected)
    }
    
    
    func testTrailingClosuresCompile() {
        weak var expectation = expectationWithDescription("`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        let promise = Promise<String> { fulfill, reject in
            delay(0.05) {
                fulfill("hello")
            }
            }.then { value in
                return Promise<Int> { fulfill, reject in
                    delay(0.05) {
                        fulfill(value.characters.count)
                    }
                }
            }.then { value in
                return value + 1
        }
        
        promise.then { value in
            expectation?.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertEqual(promise.value, 6)
        XCTAssert(promise.isFulfilled)
    }
    
    func testDoubleResolve() {
        let promise = Promise<String>()
        promise.fulfill("correct")
        promise.fulfill("incorrect")
        XCTAssertEqual(promise.value, "correct")
    }
    
    func testDoubleReject() {
        let promise = Promise<String>()
        promise.reject(NSError(domain: "com.khanlou.Pinky", code: 12, userInfo: nil))
        promise.fulfill("incorrect")
        XCTAssert(promise.isRejected)
    }
}
