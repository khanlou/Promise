//
//  Promise+Extras.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/3/16.
//
//

import Foundation
#if os(Linux)
    import Dispatch
#endif

struct PromiseCheckError: Error { }

public enum Promises {
    
    /// Wait for all the promises you give it to fulfill, and once they have, fulfill itself
    /// with the array of all fulfilled values.
    /// - Parameter promises: Promises to wait for
    /// - Returns: A Promise that is completed when all of the input promises finish.
    ///
    /// Note that `race()` is different to `all()` because `race()` will
    /// take the first promise to complete and returns that promise's results,
    /// where `all()` will wait for every promise to complete and return all of the
    /// results or the first failure. Fails if any of the input promises fail.
    public static func all<T>(_ promises: [Promise<T>]) -> Promise<[T]> {
        return Promise<[T]>(work: { fulfill, reject in
            guard !promises.isEmpty else { fulfill([]); return }
            for promise in promises {
                promise.then({ value in
                    if !promises.contains(where: { $0.isRejected || $0.isPending }) {
                        fulfill(promises.compactMap({ $0.value }))
                    }
                }).catch({ error in
                    reject(error)
                })
            }
        })
    }

    /// A promise that resolves itself after some delay.
    /// - Parameter delay: Delay to wait, in seconds
    /// - Returns: A `Promise<()>` that is resolved after `delay` seconds.
    public static func delay(_ delay: TimeInterval) -> Promise<()> {
        return Promise<()>(work: { fulfill, reject in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                fulfill(())
            })
        })
    }

    /// A promise that will be rejected after a delay.
    /// - Parameter timeout: The amount of time to wait, in seconds, before the rejection.
    /// - Returns: A Promise that is rejected after `timeout` seconds.
    public static func timeout<T>(_ timeout: TimeInterval) -> Promise<T> {
        return Promise<T>(work: { fulfill, reject in
            delay(timeout).then({ _ in
                reject(NSError(domain: "com.khanlou.Promise", code: -1111, userInfo: [ NSLocalizedDescriptionKey: "Timed out" ]))
            })
        })
    }

    /// Fulfills or rejects with the first of the input promises that completes.
    /// - Parameter promises: Promises to race
    /// - Returns: A `Promise<T>` that will be fulfilled or rejected with
    ///            the first of `promises` that completes.
    ///
    /// Note that `race()` is different to `all()` because `race()` will
    /// take the first promise to complete and returns that promise's result,
    /// where `all()` will wait for every promise to complete and return all of them.
    public static func race<T>(_ promises: [Promise<T>]) -> Promise<T> {
        return Promise<T>(work: { fulfill, reject in
            guard !promises.isEmpty else { fatalError() }
            for promise in promises {
                promise.then(fulfill, reject)
            }
        })
    }
    
    /// Retries a promise the given amount of times, after the given delay. If the
    /// given promise does not complete after `count` retries, then the rejection is
    /// passed through.
    ///
    /// - Parameters:
    ///   - count: The amount of times to retry the given promise
    ///   - delay: How much time, in seconds, between each attempt
    ///   - generate: Closure to generate the `Promise<T>`
    /// - Returns: A promise that will retry itself, after the given delay, until the
    ///            given promise is fulfilled or the maximum count is reached.
    public static func retry<T>(count: Int, delay: TimeInterval, generate: @escaping () -> Promise<T>) -> Promise<T> {
        if count <= 0 {
            return generate()
        }
        return Promise<T>(work: { fulfill, reject in
            generate().recover({ error in
                return self.delay(delay).then({
                    return retry(count: count-1, delay: delay, generate: generate)
                })
            }).then(fulfill).catch(reject)
        })
    }
    
    /// Runs a block of code that creates a `Promise` but which can also `throw`.
    /// Useful when setting up a promise with code that needs to throw.
    /// - Parameter block: Code to generate a `Promise`; `throw`ing creates a rejected promise with the thrown error.
    /// - Returns: `Promise<T>` that is created from the given block
    public static func kickoff<T>(_ block: @escaping () throws -> Promise<T>) -> Promise<T> {
        return Promise(value: ()).then(block)
    }

    /// Runs a block of code that returns a value but which can also `throw`.
    /// Useful when setting up a promise with code that needs to throw.
    /// - Parameter block: Code to generate a value that will be wrapped in the promise;
    ///   `throw`ing creates a rejected promise with the thrown error.
    /// - Returns: `Promise<T>` that executes the given block, and rejects if necessary.
    public static func kickoff<T>(_ block: @escaping () throws -> T) -> Promise<T> {
        do {
            return try Promise(value: block())
        } catch {
            return Promise(error: error)
        }
    }
    
    /// Pairs two promises and returns a promise with the results paired together.
    /// Fails if either fails.
    /// - Parameters:
    ///   - first: First promise to pair
    ///   - second: Second promise to pair
    /// - Returns: A `Promise<>` whose type is a tuple of the values of the two given promises.
    public static func zip<T, U>(_ first: Promise<T>, _ second: Promise<U>) -> Promise<(T, U)> {
        return Promise<(T, U)>(work: { fulfill, reject in
            let resolver: (Any) -> Void = { _ in
                if let firstValue = first.value, let secondValue = second.value {
                    fulfill((firstValue, secondValue))
                }
            }
            first.then(resolver, reject)
            second.then(resolver, reject)
        })
    }

    // The following zip functions have been created with the 
    // "Zip Functions Generator" playground page. If you need variants with
    // more parameters, use it to generate them.

    /// Zips 3 promises of different types into a single Promise whose
    /// type is a tuple of 3 elements.
    /// - Parameters:
    ///   - p1: First promise
    ///   - p2: Second promise
    ///   - last: Third promise
    /// - Returns: A `Promise<>` whose type is a typle of the values of the three given promises.
    public static func zip<T1, T2, T3>(_ p1: Promise<T1>, _ p2: Promise<T2>, _ last: Promise<T3>) -> Promise<(T1, T2, T3)> {
        return Promise<(T1, T2, T3)>(work: { (fulfill: @escaping ((T1, T2, T3)) -> Void, reject: @escaping (Error) -> Void) in
            let zipped: Promise<(T1, T2)> = zip(p1, p2)

            func resolver() -> Void {
                if let zippedValue = zipped.value, let lastValue = last.value {
                    fulfill((zippedValue.0, zippedValue.1, lastValue))
                }
            }
            zipped.then({ _ in resolver() }, reject)
            last.then({ _ in resolver() }, reject)
        })
    }

    /// Zips 4 promises of different types into a single Promise whose
    /// type is a tuple of 4 elements.
    /// - Parameters:
    ///   - p1: First promise
    ///   - p2: Second promise
    ///   - p3: Third promise
    ///   - last: Fourth promise
    /// - Returns: A `Promise<>` whose type is a typle of the values of the three given promises.
    public static func zip<T1, T2, T3, T4>(_ p1: Promise<T1>, _ p2: Promise<T2>, _ p3: Promise<T3>, _ last: Promise<T4>) -> Promise<(T1, T2, T3, T4)> {
        return Promise<(T1, T2, T3, T4)>(work: { (fulfill: @escaping ((T1, T2, T3, T4)) -> Void, reject: @escaping (Error) -> Void) in
            let zipped: Promise<(T1, T2, T3)> = zip(p1, p2, p3)

            func resolver() -> Void {
                if let zippedValue = zipped.value, let lastValue = last.value {
                    fulfill((zippedValue.0, zippedValue.1, zippedValue.2, lastValue))
                }
            }
            zipped.then({ _ in resolver() }, reject)
            last.then({ _ in resolver() }, reject)
        })
    }
}

extension Promise {
    /// Adds a timeout to this promise, such that if it isn't
    /// fulfilled in the given time, it will be rejected.
    /// - Parameter timeout: Timeout, in seconds
    /// - Returns: Promise that will automatically be rejected
    ///            if it doesn't complete in the given time.
    public func addTimeout(_ timeout: TimeInterval) -> Promise<Value> {
        return Promises.race(Array([self, Promises.timeout(timeout)]))
    }
    
    /// Executes a block of code when a promise is completed,
    /// irrespective of whether it was fulfilled or rejected.
    /// - Parameters:
    ///   - queue: Optional; queue to perform work on.
    ///            Defaults to the main queue.
    ///   - onComplete: Work to perform when this promise completes.
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    @discardableResult
    public func always(on queue: ExecutionContext = DispatchQueue.main, _ onComplete: @escaping () -> Void) -> Promise<Value> {
        return then(on: queue, { _ in
            onComplete()
        }, { _ in
            onComplete()
        })
    }
    
    /// Recovers a rejection with a new promise
    /// - Parameters:
    ///   - queue: Optional; queue to perform the recovery on.
    ///            Defaults to the main queue.
    ///   - recovery: Recovery routine to perform; this returns a new `Promise`
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    public func recover(on queue: ExecutionContext = DispatchQueue.main, _ recovery: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return recover(type: Error.self, on: queue, recovery)
    }
    
    /// Recovers only when a specific kind of error is found upon rejection.
    /// - Parameters:
    ///   - errorType: Type of error to recover from
    ///   - queue: Optional; queue to do the recovery on.
    ///            Defaults to the main queue.
    ///   - recovery: Routine to run to recover from the error; returns a new `Promise`.
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    public func recover<E: Error>(type errorType: E.Type, on queue: ExecutionContext = DispatchQueue.main, _ recovery: @escaping (E) throws -> Promise<Value>) -> Promise<Value> {
        return Promise(work: { fulfill, reject in
            self.then(fulfill).catch(on: queue, { anyError in
                guard let error = anyError as? E else {
                    reject(anyError)
                    return
                }

                do {
                    try recovery(error).then(fulfill, reject)
                } catch (let error) {
                    reject(error)
                }
            })
        })
    }
    
    /// Ensures that, upon the promise being fulfilled, the predicate is passed.
    /// If the predicate fails, the promise is instead rejected.
    /// - Parameter check: Check/predicate to perform if the promise is fulfilled.
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    public func ensure(_ check: @escaping (Value) -> Bool) -> Promise<Value> {
        return self.then({ (value: Value) -> Value in
            guard check(value) else {
                throw PromiseCheckError()
            }
            return value
        })
    }
    
    /// If the promise is rejected with the given `Error`, the given code is run.
    /// - Parameters:
    ///   - errorType: The type of error to handle
    ///   - onRejected: The code to run if the promise is rejected with an error of type `errorType`
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    public func `catch`<E: Error>(type errorType: E.Type, _ onRejected: @escaping (E) -> Void) -> Promise<Value> {
        return self.catch({ error in
            if let castedError = error as? E {
                onRejected(castedError)
            }
        })
    }
    
    /// Maps any error into a new kind of error.
    /// - Parameters:
    ///   - queue: Optional; queue to perform the map on.
    ///            Defaults to the main queue.
    ///   - transformError: Transformer to convert the erorr into a new error.
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    public func mapError(on queue: ExecutionContext = DispatchQueue.main, _ transformError: @escaping (Error) -> Error) -> Promise {
        return self.mapError(type: Error.self, on: queue, transformError)
    }
    
    /// Maps the specified kind of error into a new kind of error.
    /// - Parameters:
    ///   - errorType: Type of error to map *from*
    ///   - queue: Optional; queue to perform the map on.
    ///            Defaults to the main queue.
    ///   - transformError: Transformer to convert an error of type `errorType` into a new error.
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    public func mapError<E: Error>(type errorType: E.Type, on queue: ExecutionContext = DispatchQueue.main, _ transformError: @escaping (E) -> Error) -> Promise {
        return self.recover(type: errorType, on: queue, { (error) -> Promise<Value> in
            return Promise(error: transformError(error))
        })
    }
}

#if !swift(>=4.1)
    internal extension Sequence {
        func compactMap<T>(_ fn: (Element) throws -> T?) rethrows -> [T] {
            return try flatMap { try fn($0).map { [$0] } ?? [] }
        }
    }
#endif
