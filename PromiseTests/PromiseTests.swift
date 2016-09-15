//
//  PromiseTests.swift
//  PromiseTests
//
//  Created by Soroush Khanlou on 8/1/16.
//
//

import XCTest
@testable import Promise

class PromiseTests: XCTestCase {

    func testThen() {
        weak var expectation = self.expectation(description: "The then function should be called twice.")
        var count = 0
        
        let promise = Promise(value: 5).then({ _ in
            count += 1
        }).then({ _ in
            count += 1
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(count == 2)
        XCTAssert(promise.isFulfilled)
    }
    
    func testAsync() {
        weak var expectation = self.expectation(description: "The `work:` based constructor of Promise should work correctly.")
        Promise<String>(work: { (fulfill, reject) in
            delay(0.05) {
                fulfill("hey")
            }
        }).then({ string in
            XCTAssertEqual(string, "hey")
            expectation?.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testAsyncRejection() {
        weak var expectation = self.expectation(description: "Calling `reject` from the `work:` constructor should cause the Promise to be rejceted.")
        let promise = Promise<String>(work: { (fulfill, reject) in
            delay(0.05) {
                reject(SimpleError())
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
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNotNil(promise.error)
        XCTAssert(promise.isRejected)
    }
    
    func testThenWhenPending() {
        weak var expectation = self.expectation(description: "Pending Promises shouldn't call their `then` callbacks.")
        
        var thenCalled = false
        
        Promise().then({ (value: Int) -> Int in
            thenCalled = true
            return 2
        })
        delay(0.05) {
            expectation?.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(thenCalled)
    }
    
    func testRejectedAfterFulfilled() {
        weak var expectation = self.expectation(description: "A Promise that is rejected after being fulfilled should not call any further `then` callbacks.")
        
        var thenCalled = false
        
        let promise = Promise(value: 5).then({ _ in
            thenCalled = true
        })
        
        promise.then({ _ in
            XCTFail()
        })
        
        promise.reject(SimpleError())
        
        delay(0.05) {
            expectation?.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(thenCalled)
        XCTAssert(promise.isRejected)
    }
    
    func testPending() {
        let promise = Promise<Int>()
        
        XCTAssert(promise.isPending)
    }
    
    func testFulfilled() {
        weak var expectation = self.expectation(description: "A Promise that has `fulfill` called on it should be fulfilled with the value passed to `fullfill`.")
        
        let promise = Promise<Int>()
        
        promise.then({ value in
            XCTAssertEqual(value, 10)
        })
        
        promise.fulfill(10)
        
        delay(0.05) {
            expectation?.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(promise.value == 10)
        XCTAssert(promise.isFulfilled)
    }
    
    func testRejected() {
        weak var expectation = self.expectation(description: "A Promise that is rejected should have its `onFailure` method called.")
        
        let error = SimpleError()
        let promise = Promise<Int>()
        
        promise.onFailure({ _ in
            expectation?.fulfill()
        })
        
        promise.reject(error)
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(promise.error as? SimpleError, error)
        XCTAssert(promise.isRejected)
    }
    
    func testMap() {
        weak var expectation = self.expectation(description: "")
        
        let promise = Promise(value: "someString").then({ string in
            return string.characters.count
        }).then({ count in
            return count*2
        }).then({ doubled in
            XCTAssertEqual(doubled, 20)
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(promise.value, 20)
        XCTAssert(promise.isFulfilled)
    }
    
    func testFlatMap() {
        weak var expectation = self.expectation(description: "A `then` callback that returns another Promise should execute and fulfill the next Promise.")
        let promise = Promise<String>(work: { fulfill, reject in
            delay(0.05) {
                fulfill("hello")
            }
        }).then({ value in
            return Promise<Int>(work: { fulfill, reject in
                delay(0.05) {
                    fulfill(value.characters.count)
                }
            })
        }).then({ value in
            XCTAssertEqual(value, 5)
            expectation?.fulfill()
        })
        
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(promise.value, 5)
        XCTAssert(promise.isFulfilled)
    }
        
    func testTrailingClosuresCompile() {
        weak var expectation = self.expectation(description: "`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
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
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(promise.value, 6)
        XCTAssert(promise.isFulfilled)
    }
    
    func testDoubleResolve() {
        let promise = Promise<String>()
        promise.fulfill("correct")
        promise.fulfill("incorrect")
        XCTAssertEqual(promise.value, "correct")
    }
    
    func testRejectThenResolve() {
        let promise = Promise<String>()
        promise.reject(SimpleError())
        promise.fulfill("incorrect")
        XCTAssert(promise.isRejected)
    }

    func testDoubleReject() {
        let promise = Promise<String>()
        promise.reject(SimpleError())
        promise.reject(SimpleError())
        XCTAssert(promise.isRejected)
    }
    
    func testResolveThenReject() {
        let promise = Promise<String>()
        promise.fulfill("correct")
        promise.reject(SimpleError())
        XCTAssertEqual(promise.value, "correct")
    }
}
