//
//  PromiseZipTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/19/16.
//
//

import XCTest
import Foundation

import Promise

class PromiseZipTests: XCTestCase {
    func testZipping2() {
        weak var expectation = self.expectation(description: "`Promises.zip` should be type safe.")

        let promise = Promise(value: 2)
        let promise2 = Promise(value: "some string")
        let zipped = Promises.zip(promise, promise2)
        zipped.always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        guard let tuple = zipped.value else { XCTFail(); return }
        XCTAssertEqual(tuple.0, 2)
        XCTAssertEqual(tuple.1, "some string")
    }
}
