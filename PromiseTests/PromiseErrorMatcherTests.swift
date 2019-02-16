//
//  PromiseErrorMatcherTests.swift
//  PromiseTests
//
//  Created by Soroush Khanlou on 2/16/19.
//

import XCTest
import Promise


class PromiseErrorMatcherTests: XCTestCase {
    
    func testCasting() {
        weak var expectation = self.expectation(description: "`Promise.catch` should always cast the error type.")
        
        var flag = false

        Promise<Void>(error: WrenchError(message: "testing"))
            .then({
                XCTFail()
            })
            .catch(type: WrenchError.self, { wrenchError in
                self.functionThatOnlyWorksWithWrenchErrors(wrenchError)
                flag = true
            })
            .always({
                expectation?.fulfill()
            })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(flag)
    }
    
    func testCastingFailing() {
        weak var expectation = self.expectation(description: "`Promise.catch` should always cast the error type.")
        
        var flag = false
        
         Promise<Void>(error: SimpleError())
            .catch({ error in
                flag = !(error is WrenchError)
            })
            .catch(type: WrenchError.self, { wrenchError in
                self.functionThatOnlyWorksWithWrenchErrors(wrenchError)
                XCTFail()
            })
            .always({
                expectation?.fulfill()
            })
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(flag)
    }
    
    func functionThatOnlyWorksWithWrenchErrors(_ error: WrenchError) {
        _ = 1 + 1
    }
    
}
