import XCTest
@testable import Promise

final class PromiseErrorTests: XCTestCase {
    func testMapErrorChangesError() {
        let p = Promise<Int>()
        let e = expectation(description: "mapError")

        var error: WrenchError?
        p.mapError { (e) -> Error in
            return WrenchError(message: "Changed")
        }.catch(type: WrenchError.self) { caughtError in
            error = caughtError
        }.always{
            e.fulfill()
        }

        p.reject(WrenchError(message: "Original"))

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(error?.message, "Changed")
    }

    func testTypedMapErrorChangesError() {
        let p = Promise<Int>()
        let e = expectation(description: "mapError")

        var error: WrenchError?
        p.mapError(type: PromiseCheckError.self) { (e) -> Error in
            return WrenchError(message: "Changed")
        }.catch(type: WrenchError.self) { caughtError in
            error = caughtError
        }.always{
            e.fulfill()
        }

        p.reject(PromiseCheckError())

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(error?.message, "Changed")
    }

    func testTypedMapErrorDoesntChangeErrorsOfUnspecifiedType() {
        let p = Promise<Int>()
        let e = expectation(description: "mapError")

        var error: WrenchError?
        p.mapError(type: PromiseCheckError.self) { (e) -> Error in
            return WrenchError(message: "Changed")
        }.catch(type: WrenchError.self) { caughtError in
            error = caughtError
        }.always{
            e.fulfill()
        }

        p.reject(WrenchError(message: "Original"))

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(error?.message, "Original")
    }

    static let allTests = [
        ("testMapErrorChangesError", testMapErrorChangesError),
        ("testTypedMapErrorChangesError", testTypedMapErrorChangesError),
        ("testTypedMapErrorDoesntChangeErrorsOfUnspecifiedType", testTypedMapErrorDoesntChangeErrorsOfUnspecifiedType),
        ]
}
