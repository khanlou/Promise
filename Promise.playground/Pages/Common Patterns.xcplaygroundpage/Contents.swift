
import Promise  // <-- If there is an error here, build the project first.

/*

 Playing with the ideas in http://khanlou.com/2016/08/common-patterns-with-promises/

 Set each `if false` to `true` to run that example.

 */



/// Helper function to build/fulfill a Promise.
/// - returns: A Promise that fulfills with the given string, after a delay.
func promisedString(_ str: String) -> Promise<String> {
    return Promise<String>(work: { fulfill, reject in
        sleep(1)
        fulfill(str)
    })
}



// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Using .all()

if false {
    print("Running .all() example")

    let strings = [ "a", "b", "c" ]
    let promises = strings.map(promisedString)

    Promise<[String]>.all(promises).then({ allStrings -> Void in
        print("got em all:", allStrings)
    })
}



// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Using .delay()

if false {
    print("Running .delay() example")

    Promise<Void>.delay(1.0).then({ _ -> Void in
        print("after delay")
    })
}


// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Race

if false {
    print("Running .race() example")

    let strings = [ "a", "b", "c", "d", "e", "f" ]
    let promises = strings.map(promisedString)

    Promise<String>.race(promises).then({ (value) -> Void in
        // If you run this multiple times, you might get a different result each time
        print("got: \(value)")
    })
}



// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Timeout

if false {
    print("Running .timeout() example")

    promisedString("timeout")
        .addTimeout(0.5)  // NOTE: 0.5 will fail, 1.5 will succeed
        .then({ _ -> Void in
            print("success from timeout")
        })
        .onFailure({ error in
            print("failure from timeout: \(error)")
        })
}



// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Recover

/// Helper function to make a promise that succeeds or fails from the given value
func failablePromise(_ str: String, fail: Bool) -> Promise<String> {
    return Promise<String>(work: { fulfill, reject in
        if fail {
            reject(NSError(domain: "rejected", code: 1, userInfo: nil))
        }
        else {
            fulfill(str)
        }
    })
}

if false {
    print("Running .recover() example")

    // NOTE: toggle these `fail:` values to try different outcomes

    failablePromise("recovery", fail: true)
        .then({ result -> Void in
            print("succeeded: \(result)")
        }).onFailure({ error in
            print("failed \(error)")
        })

    failablePromise("recovery", fail: true)
        .recover({ _ in
            // e.g. fallback to fetch from the server
            print("going to fetch from server…")
            return promisedString("from server")
        }).then({ result -> Void in
            print("succeeded: \(result)")
        }).onFailure({ error in
            print("failed \(error)")
        })
}


// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Retry

if false {
    print("Running .retry() example")

    var i = 0
    Promise<String>.retry(count: 5, delay: 0.5, generate: { () -> Promise<String> in
        print("generating \(i)")
        i += 1
        return failablePromise("retry", fail: i<3)
    }).then({ result -> Void in
        print("got result:", result)
    }).onFailure({ error in
        print("failed: \(error)")
    })
}





// - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Run the playground so the `dispatch_async()`s work
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
