import XCTest
@testable import PromiseTests

XCTMain([
    testCase(ExecutionContextTests.allTests),
    testCase(PromiseAllTests.allTests),
    testCase(PromiseAlwaysTests.allTests),
    testCase(PromiseDelayTests.allTests),
    testCase(PromiseEnsureTests.allTests),
    testCase(PromiseKickoffTests.allTests),
    testCase(PromiseRaceTests.allTests),
    testCase(PromiseRecoverTests.allTests),
    testCase(PromiseRetryTests.allTests),
    testCase(PromiseTests.allTests),
    testCase(PromiseThrowsTests.allTests),
    testCase(PromiseZipTests.allTests),
])
