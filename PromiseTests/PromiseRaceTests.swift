//
//  PromiseRaceTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
@testable import Promise

class PromiseRaceTests: XCTestCase {

    func testRace() {
        weak var expectation = expectationWithDescription("`Promise.race` should wait until multiple promises are fulfilled before returning.")
        
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
            delay(0.09) {
                fulfill(3)
            }
        })
        
        let final = Promise<Int>.race([promise1, promise2, promise3])
        
        final.then({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        guard let int = final.value else { XCTFail(); return }
        XCTAssertEqual(int, 2)
        XCTAssert(final.isFulfilled)
    }

    func testRaceFailure() {
        weak var expectation = expectationWithDescription("`Promise.race` should wait until multiple promises are fulfilled before returning.")
        
        let promise1 = Promise<Int>(work: { fulfill, reject in
            delay(0.05) {
                reject(NSError(domain: "com.khanlou.Promise", code: -1111, userInfo: [ NSLocalizedDescriptionKey: "Timed out" ]))
            }
        })
        let promise2 = Promise<()>.delay(0.1).then({ 2 })
        
        let final = Promise<Int>.race([promise1, promise2])
        
        final.onFailure({ _ in
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssert(final.isRejected)
    }

}
