//
//  PromiseErrorMatcherTests.swift
//  PromiseTests
//
//  Created by Soroush Khanlou on 2/16/19.
//

import XCTest
import Promise


class PromiseErrorMatcherTests: XCTestCase {
    
    func testCastingExecutesMatchingErrors() {
        weak var expectation = self.expectation(description: "`Promise.catch` should cast the error when it is the right type.")
        
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
    
    func testCastingIgnoresNonMatchingErrors() {
        weak var expectation = self.expectation(description: "`Promise.catch` should not cast the error when it is the wrong type.")
        
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
    
    static let allTests = [
        ("testCastingIgnoresNonMatchingErrors", testCastingIgnoresNonMatchingErrors),
        ("testCastingExecutesMatchingErrors", testCastingExecutesMatchingErrors),
        ]

}
