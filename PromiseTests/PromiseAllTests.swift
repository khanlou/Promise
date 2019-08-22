//
//  PromiseAllTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/2/16.
//
//

import XCTest
import Promise

class PromiseAllTests: XCTestCase {
    func testAll() {
        weak var expectation = self.expectation(description: "`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
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
        
        let final = Promises.all([promise1, promise2, promise3, promise4])
        
        final.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        guard let array = final.value else { XCTFail(); return }
        XCTAssertEqual(array, [1, 2, 3, 4])
        XCTAssert(final.isFulfilled)
    }
    
    func testAllWithPreFulfilledValues() {
        weak var expectation = self.expectation(description: "`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        let promise1 = Promise(value: 1)
        let promise2 = Promise(value: 2)
        let promise3 = Promise(value: 3)
        
        let final = Promises.all([promise1, promise2, promise3])
        
        final.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        guard let array = final.value else { XCTFail(); return }
        XCTAssertEqual(array, [1, 2, 3])
        XCTAssert(final.isFulfilled)
    }
    
    func testAllWithEmptyArray() {
        weak var expectation = self.expectation(description: "`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        
        let final: Promise<[Int]> = Promises.all([])
        final.always({
            expectation?.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
        guard let array = final.value else { XCTFail(); return }
        XCTAssertEqual(array, [])
        XCTAssert(final.isFulfilled)
    }
    
    func testAllWithRejectionHappeningFirst() {
        weak var expectation = self.expectation(description: "`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        let promise1 = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                fulfill(2)
            }
        })
        let promise2 = Promise<Int>(work: { fulfill, reject in
            delay(0.05) {
                reject(SimpleError())
            }
        })
        
        let final = Promises.all([promise1, promise2])
        
        final.then({ _ in
            XCTFail()
        })
        
        final.then({ _ in
            XCTFail()
        })
        
        final.catch({ _ in
            expectation?.fulfill()
        })
        
        final.then({ _ in
            XCTFail()
        })
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertNotNil(final.error)
        XCTAssert(final.isRejected)
    }
    
    func testAllWithRejectionHappeningLast() {
        weak var expectation = self.expectation(description: "`Promise.all` should wait until multiple promises are fulfilled before returning.")
        
        let promise1 = Promise<Int>(work: { fulfill, reject in
            delay(0.05) {
                fulfill(2)
            }
        })
        let promise2 = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                reject(SimpleError())
            }
        })
        
        let final = Promises.all([promise1, promise2])
        
        final.then({ _ in
            XCTFail()
        })
        
        final.then({ _ in
            XCTFail()
        })
        
        final.catch({ _ in
            expectation?.fulfill()
        })
        
        final.then({ _ in
            XCTFail()
        })
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertNotNil(final.error)
        XCTAssert(final.isRejected)
    }
    
    static let allTests = [
        ("testAll", testAll),
        ("testAllWithPreFulfilledValues", testAllWithPreFulfilledValues),
        ("testAllWithEmptyArray", testAllWithEmptyArray),
        ("testAllWithRejectionHappeningFirst", testAllWithRejectionHappeningFirst),
        ("testAllWithRejectionHappeningLast", testAllWithRejectionHappeningLast),
    ]
}
