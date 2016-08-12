//
//  PromiseRecoverTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/11/16.
//
//

import XCTest
@testable import Promise

class PromiseRecoverTests: XCTestCase {
    func testRecover() {
        weak var expectation = expectationWithDescription("`Promise.recover` should recover from errors.")
        
        let promise = Promise<Int>(work: { fulfill, reject in
            delay(0.1) {
                reject(SimpleError())
            }
        }).recover({ error in
            XCTAssert(error as? SimpleError == SimpleError())
            return Promise(work: { (fulfill, reject) in
                fulfill(5)
            })
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(1, handler: nil)
        guard let int = promise.value else { XCTFail(); return }
        XCTAssertEqual(int, 5)
        XCTAssert(promise.isFulfilled)
    }
}
