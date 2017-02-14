# Promise

![](https://api.travis-ci.org/khanlou/Promise.svg)

A Promise library for Swift, based partially on [Javascript's A+ spec](https://promisesaplus.com/).

## What is a Promise?

A Promise is a way to represent a value that will exist (or will fail with an error) at some point in the future. This is similar to how an `Optional` represents a value that may or may not be there.

Using a special type to represent values that will exist in the future means that those values can be combined, transformed, and built in systematic ways. If the system knows what success and what failure look like, composing those asynchronous operations becomes much easier. For example, it becomes trivial to write reusable code that can:

* perform a chain of dependent asynchronous operations with one completion block at the end
* perform many independent asynchronous operations simultaneously with one completion block
* race many asynchronous operations and return the value of the first to complete
* retry asynchronous operations
* add a timeout to asynchronous operations

Promises are suited for any asynchronous action that can succeed or fail exactly once, such as HTTP requests. If there is an asynchronous action that can "succeed" more than once, or delivers a series of values over time instead of just one, take a look at [Signals](https://github.com/JensRavens/Interstellar/) or [Observables](https://github.com/ReactiveX/RxSwift).

## Basic Usage

To access the value once it arrives, you call the `then` method with a block.
```swift
let usersPromise = fetchUsers() // Promise<[User]>
usersPromise.then({ users in
    self.users = users
})
```
All usage of the data in the `users` Promise is gated through the `then` method.

In addition to performing side effects (like setting the `users` instance variable on `self`), `then` enables you do two other things. First, you can transform the contents of the Promise, and second, you can kick off another Promise, to do more asynchronous work. To do either of these things, return something from the block you pass to `then`. Each time you call `then`, the existing Promise will return a new Promise.
```swift
let usersPromise = fetchUsers() // Promise<[User]>
let firstUserPromise = usersPromise.then({ users in // Promise<User>
    return users[0]
})
let followersPromise = firstUserPromise.then({ firstUser in //Promise<[Follower]>
    return fetchFollowers(of: firstUser)
})
followersPromise.then({ followers in
    self.followers = followers
})
```
Based on whether you return a regular value or a promise, the `Promise` will determine whether it should transform the internal contents, or fire off the next promise and await its results.

As long as the block you pass to `then` is one line long, its type signature will be inferred, which will make Promises much easier to read and work with.

Since each call to `then` returns a new `Promise`, you can write them in a big chain. The code above, as a chain, would be written:
```swift
fetchUsers()
    .then({ users in
        return users[0]
    })
    .then({ firstUser in
        return fetchFollowers(of: firstUser)
    })
    .then({ followers in
        self.followers = followers
    })
```
To catch any errors that are created along the way, you can add a `catch` block as well:
```swift
fetchUsers()
    .then({ users in
        return users[0]
    })
    .then({ firstUser in
        return fetchFollowers(of: firstUser)
    })
    .then({ followers in
        self.followers = followers
    })
    .catch({ error in
        displayError(error)
    })
```
If any step in the chain fails, no more `then` blocks will be executed. Only failure blocks are executed. This is enforced in the type system as well. If the `fetchUsers()` promise fails (for example, because of a lack of internet), there's no way for the promise to construct a valid value for the `users` variable, and there's no way that block could be called.

## Creating Promises

To create a promise, there is a convenience initializer that takes a block and provides functions to `fulfill` or `reject` the promise:

```swift
let promise = Promise<Data>(work: { fulfill, reject in
    try fulfill(Data(contentsOf: someURL)
})
```

It will automatically run on a global background thread. 

You can use this initializer to wrap a completion block-based API, like `URLSession`.

```swift
let promise = Promise<(Data, HTTPURLResponse)>(work: { fulfill, reject in
    self.dataTask(with: request, completionHandler: { data, response, error in
        if let error = error {
            reject(error)
        } else if let data = data, let response = response as? HTTPURLResponse {
            fulfill((data, response))
        } else {
            fatalError("Something has gone horribly wrong.")
        }
    }).resume()
})
```

If the API that you're wrapping is sensitive to which thread it's being run on, like any UIKit code, be sure to pass add a `queue: .main` parameter to the `work:` initializer, and it will be executed on the main queue.

For delegate-based APIs, you can can create a promise in the `.pending` state with the default initializer.

```swift
let promise = Promise()
```

and use the `fulfill` and `reject` instance methods to change its state. 

## Advanced Usage

Because promises formalize how success and failure blocks look, it's possible to build behaviors on top of them. 

### `always`

For example, if you want to execute code when the promise fulfills — regardless of whether it succeeds or fails – you can use `always`.
```swift
activityIndicator.startAnimating()
fetchUsers()
    .then({ users in
        self.users = users
    })
    .always({
        self.activityIndicator.stopAnimating()
    })
```
Even if the network request fails, the activity indicator will stop. Note that the block that you pass to `always` has no parameters. Because the `Promise` doesn't know if it will succeed or fail, it will give you neither a value nor an error.

### `all`

`Promise.all` is a static method that waits for all the promises you give it to fulfill, and once they have, it fulfills itself with the array of all fulfilled values. For example, you might want to write code to hit an API endpoint once for each item in an array. `map` and `Promise.all` make that super easy:
```swift
let userPromises = users.map({ user in
    APIClient.followUser(user)
})
Promise<()>.all(userPromises)
    .then({
        //all the users are now followed!
    })
    .catch  ({ error in
        //one of the API requests failed
    })
```
### `ensure`

`ensure` is a method that takes a predicate, and rejects the promise chain if that predicate fails.
```swift
URLSession.shared.dataTask(with: request)
    .ensure({ data, httpResponse in
        return httpResponse.statusCode == 200
    })
    .then({ data, httpResponse in
        // the statusCode is valid
    })
    .catch({ error in 
        // the network request failed, or the status code was invalid
    })
```
### Others

These are some of the most useful behaviors, but there are others as well, like `race` (which races multiple promises), `retry` (which lets you retry a single promise multiple times), and `recover` (which lets you return a new `Promise` given an error, allowing you to recover from failure), and others.

You can find these behaviors in the [Promises+Extras.swift](https://github.com/khanlou/Promise/blob/master/Promise/Promise%2BExtras.swift) file.

## Ease of Use

I made several design decisions when writing this `Promise` library, erring towards making the library as easy to use as possible.

### Simplified Naming

Other promise libraries use the functional names for `then`, such as `map` and `flatMap`. The benefit to using these monadic functional terms is minor, but cost, in terms of understanding, is high. In this library, you call `then`, and return anything you need to, and the library figures out how to handle it.

### Error Parameterization

Other promise libraries allow you to define what type the error each promise will return. In theory, this a useful feature, allowing you to know what type the error will be in `catch` blocks.

In practice, this is stifling. In practice, if you're using errors from two different domains, you have to either a) use a lowest common denominator error, like `NSError`, or b) call a method like `mapError` to convert the error from one domain to another.

Also note that Swift's built-in error handling system doesn't have typed errors, opting for pattern matching instead.

### Throwing

Lastly, you can use `try` and `throw` from within all the blocks, and the library will automatically translate it to a promise rejection. This makes working with APIs that throw much more easily. To extend our `URLSession` example, we can use the throwing JSONSerialization API easily.
```swift
URLSession.shared.dataTask(with: request)
    .ensure({ data, httpResponse in httpResponse.statusCode == 200 })
    .then({ data, httpResponse in
        return try JSONSerialization.jsonObject(with: data)
    })
    .then({ json in
        // use the json
    })
```
Working with optionals can be made simpler with a little extension.
```swift
struct NilError: Error { }

extension Optional {
    func unwrap() throws -> Wrapped {
        guard let result = self else {
            throw NilError()
        }
        return result
    }
}
```
Because you're in an environment where you can freely throw and it will be handled for you (in the form of a rejected Promise), you can now easily unwrap optionals. For example, if you need a specific key out of a json dictionary:
```swift
.then({ json in
    return try (json["user"] as? [String: Any]).unwrap()
})
```
And you will transform your optional into a non-optional.

### Threading Model

The threading model for this library is dead simple. `init(work:)` happens on a background queue by default, and every other block-based method (`then`, `catch`, `always`, etc) executes on the main thread. These can be overridden by passing in a `DispatchQueue` object for the first parameter.

```swift
Promise<Void>(queue: .main, work: { fulfill, reject in
    viewController.present(viewControllerToPresent, animated: flag, completion: {
        fulfill()
    })
}).then(on: .global(), {
    return try Data(contentsOf: someURL)
}).then(on: .main, {
    self.data = data
})
```

## Playing Around

To get started playing with this library, you can use the included `Promise.playground`.  Simply open the `.xcodeproj`, build the scheme, and then open the playground (from within the project) and start playing.

