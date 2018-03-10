//
//  PromiseRaceTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
import Promise

class PromiseRaceTests: XCTestCase {
    
    func testRace() {
        weak var expectation = self.expectation(description: "`Promise.race` should fulfill as soon as the first promise is fulfilled.")
        
        let promise1 = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                fulfill(1)
            }
        })
        let promise2 = Promise<Int>(work: { fulfill, reject in
            delay(0.05) {
                fulfill(2)
            }
        })
        let promise3 = Promise<Int>(work: { fulfill, reject in
            delay(0.15) {
                fulfill(3)
            }
        })
        
        let final = Promises.race([promise1, promise2, promise3])
        
        final.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        guard let int = final.value else { XCTFail(); return }
        XCTAssertEqual(int, 2)
        XCTAssert(final.isFulfilled)
    }
    
    func testRaceFailure() {
        weak var expectation = self.expectation(description: "`Promise.race` should reject as soon as the first promise is reject.")
        
        let promise1 = Promise<Int>(work: { fulfill, reject in
            delay(0.05) {
                reject(SimpleError())
            }
        })
        let promise2 = Promises.delay(0.1).then({ 2 })
        
        let final = Promises.race([promise1, promise2])
        
        final.catch({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(final.isRejected)
    }
    
    func testInstantResolve() {
        weak var expectation = self.expectation(description: "`Promise.race` should reject as soon as the first promise is reject.")
        
        let promise1 = Promise<Int>(value: 1)
        let promise2 = Promises.delay(0.1).then({ 5 })
        
        let final = Promises.race([promise1, promise2])
        
        final.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(final.isFulfilled)
        XCTAssertEqual(final.value, 1)
    }
    
    func testInstantReject() {
        weak var expectation = self.expectation(description: "`Promise.race` should reject as soon as the first promise is reject.")
        
        let promise1 = Promise<Int>(error: SimpleError())
        let promise2 = Promises.delay(0.1).then({ 5 })
        
        let final = Promises.race([promise1, promise2])
        
        final.catch({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(final.isRejected)
    }

    static let allTests = [
        ("testRace", testRace),
        ("testRaceFailure", testRaceFailure),
        ("testInstantResolve", testInstantResolve),
        ("testInstantReject", testInstantReject),
    ]
}
