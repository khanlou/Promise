import XCTest
@testable import Promise

final class PromiseErrorTests: XCTestCase {
    func testMapErrorChangesError() {
        let p = Promise<Int>()
        let e = expectation(description: "mapError")

        var error: Error?
        p.mapError { (e) -> Error in
            return GeneralError("Changed")
        }.catch { (caughtError) in
            error = caughtError
        }.always {
            e.fulfill()
        }

        p.reject(GeneralError("Original"))

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual((error as? GeneralError)?.message, "Changed")
    }

    func testRejectWithMessageRejectsPromise() {
        let p = Promise<Void>()
        let e = expectation(description: "reject with message")

        var error: Error?
        p.catch { (caughtError) in
            error = caughtError
        }.always {
            e.fulfill()
        }

        p.reject(errorMessage: "some error")

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssert(error is GeneralError)
        XCTAssertEqual((error as? GeneralError)?.message, "some error")
    }

    func testErrorInitializer() {
        let p = Promise<Void>(errorMessage: "some error")
        let e = expectation(description: "error initializer")

        var error: Error?
        p.catch { (caughtError) in
            error = caughtError
        }.always {
            e.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssert(error is GeneralError)
        XCTAssertEqual((error as? GeneralError)?.message, "some error")
    }
}
