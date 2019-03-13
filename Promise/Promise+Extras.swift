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

    /// Resolves itself after some delay.
    /// - parameter delay: In seconds
    public static func delay(_ delay: TimeInterval) -> Promise<()> {
        return Promise<()>(work: { fulfill, reject in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                fulfill(())
            })
        })
    }

    /// This promise will be rejected after a delay.
    public static func timeout<T>(_ timeout: TimeInterval) -> Promise<T> {
        return Promise<T>(work: { fulfill, reject in
            delay(timeout).then({ _ in
                reject(NSError(domain: "com.khanlou.Promise", code: -1111, userInfo: [ NSLocalizedDescriptionKey: "Timed out" ]))
            })
        })
    }

    /// Fulfills or rejects with the first promise that completes
    /// (as opposed to waiting for all of them, like `.all()` does).
    public static func race<T>(_ promises: [Promise<T>]) -> Promise<T> {
        return Promise<T>(work: { fulfill, reject in
            guard !promises.isEmpty else { fatalError() }
            for promise in promises {
                promise.then(fulfill, reject)
            }
        })
    }

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

    public static func kickoff<T>(_ block: @escaping () throws -> Promise<T>) -> Promise<T> {
        return Promise(value: ()).then(block)
    }

    public static func kickoff<T>(_ block: @escaping () throws -> T) -> Promise<T> {
        do {
            return try Promise(value: block())
        } catch {
            return Promise(error: error)
        }
    }

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
    public func addTimeout(_ timeout: TimeInterval) -> Promise<Value> {
        return Promises.race(Array([self, Promises.timeout(timeout)]))
    }

    @discardableResult
    public func always(on queue: ExecutionContext = DispatchQueue.main, _ onComplete: @escaping () -> Void) -> Promise<Value> {
        return then(on: queue, { _ in
            onComplete()
        }, { _ in
            onComplete()
        })
    }

    public func recover(_ recovery: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return Promise(work: { fulfill, reject in
            self.then(fulfill).catch({ error in
                do {
                    try recovery(error).then(fulfill, reject)
                } catch (let error) {
                    reject(error)
                }
            })
        })
    }

    public func ensure(_ check: @escaping (Value) -> Bool) -> Promise<Value> {
        return self.then({ (value: Value) -> Value in
            guard check(value) else {
                throw PromiseCheckError()
            }
            return value
        })
    }
    
    public func `catch`<E: Error>(type errorType: E.Type, _ onRejected: @escaping (E) -> Void) -> Promise<Value> {
        return self.catch({ error in
            if let castedError = error as? E {
                onRejected(castedError)
            }
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
