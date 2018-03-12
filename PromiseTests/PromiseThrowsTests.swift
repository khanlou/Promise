//
//  PromiseThrowsTests.swift
//  Promise
//
//  Created by Soroush Khanlou on 9/14/16.
//
//

import XCTest
import Promise

class PromiseThrowsTests: XCTestCase {

    func testThrowsInMapping() {
        weak var expectation = self.expectation(description: "`Promise.zip` should be type safe.")
        
        let promise = Promise(value: 2).then({ (value: Int) -> Int in
            if value == 3 {
                throw SimpleError()
            }
            return 5
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(promise.value, 5)
    }
    
    func testThrowsInMappingWithError() {
        weak var expectation = self.expectation(description: "`Promise.zip` should be type safe.")
        
        let promise = Promise(value: 2).then({ (value: Int) -> Int in
            if value == 2 {
                throw SimpleError()
            }
            return 5
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.error is SimpleError)
    }
    
    func testThrowsInFlatmapping() {
        weak var expectation = self.expectation(description: "`Promise.zip` should be type safe.")
        
        let promise = Promise(value: 2).then({ (value: Int) -> Promise<Int> in
            if value == 3 {
                throw SimpleError()
            }
            return Promise(value: 5)
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(promise.value, 5)
    }
    
    func testThrowsInFlatmappingWithError() {
        weak var expectation = self.expectation(description: "`Promise.zip` should be type safe.")
        
        let promise = Promise(value: 2).then({ (value: Int) -> Promise<Int> in
            if value == 2 {
                throw SimpleError()
            }
            return Promise(value: 5)
        }).always({
            expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(promise.error is SimpleError)
    }

    static let allTests = [
        ("testThrowsInMapping", testThrowsInMapping),
        ("testThrowsInMappingWithError", testThrowsInMappingWithError),
        ("testThrowsInFlatmapping", testThrowsInFlatmapping),
        ("testThrowsInFlatmappingWithError", testThrowsInFlatmappingWithError),
    ]
}
