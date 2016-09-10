
import Promise  // <-- If there is an error here, build the project first.

/*

 Basic usage of a Promise.

 */

/// Helper function to build/fulfill a Promise.
/// - returns: A Promise that fulfills with the given string, after a delay.
func promisedString(str: String) -> Promise<String> {
    return Promise<String>(work: { fulfill, reject in
        print("sleeping…")
        sleep(1)
        print("done sleeping")
        fulfill(str)
    })
}


promisedString("simple example").then { result in
    print("Got result: ", result)
}

print("after creating promise")






// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Run the playground so the `dispatch_async()`s work
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
