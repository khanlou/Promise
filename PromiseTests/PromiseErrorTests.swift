import XCTest
@testable import Promise

final class PromiseErrorTests: XCTestCase {
    func testMapErrorChangesError() {
        let p = Promise<Int>()
        let e = expectation(description: "mapError")

        var error: WrenchError?
        p.mapError { (e) -> Error in
            return WrenchError(message: "Changed")
        }.catch { (caughtError: WrenchError) in
            error = caughtError
        }.always {
            e.fulfill()
        }

        p.reject(WrenchError(message: "Original"))

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(error.message, "Changed")
    }
}
