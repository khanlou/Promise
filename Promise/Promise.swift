//
//  Promise.swift
//  Promise
//
//  Created by Soroush Khanlou on 7/21/16.
//
//

import Foundation
#if os(Linux)
    import Dispatch
#endif

public protocol ExecutionContext {
    func execute(_ work: @escaping () -> Void)
}

extension DispatchQueue: ExecutionContext {

    public func execute(_ work: @escaping () -> Void) {
        self.async(execute: work)
    }
}

public final class InvalidatableQueue: ExecutionContext {

    private var valid = true

    private var queue: DispatchQueue

    public init(queue: DispatchQueue = .main) {
        self.queue = queue
    }

    public func invalidate() {
        valid = false
    }

    public func execute(_ work: @escaping () -> Void) {
        guard valid else { return }
        self.queue.async(execute: work)
    }

}

struct Callback<Value> {
    let onFulfilled: (Value) -> Void
    let onRejected: (Error) -> Void
    let executionContext: ExecutionContext
    
    func callFulfill(_ value: Value, completion: @escaping () -> Void = { }) {
        executionContext.execute({
            self.onFulfilled(value)
            completion()
        })
    }
    
    func callReject(_ error: Error, completion: @escaping () -> Void = { }) {
        executionContext.execute({
            self.onRejected(error)
            completion()
        })
    }
}

enum State<Value>: CustomStringConvertible {

    /// The promise has not completed yet.
    /// Will transition to either the `fulfilled` or `rejected` state.
    case pending(callbacks: [Callback<Value>])

    /// The promise now has a value.
    /// Will not transition to any other state.
    case fulfilled(value: Value)

    /// The promise failed with the included error.
    /// Will not transition to any other state.
    case rejected(error: Error)


    var isPending: Bool {
        if case .pending = self {
            return true
        } else {
            return false
        }
    }
    
    var isFulfilled: Bool {
        if case .fulfilled = self {
            return true
        } else {
            return false
        }
    }
    
    var isRejected: Bool {
        if case .rejected = self {
            return true
        } else {
            return false
        }
    }
    
    var value: Value? {
        if case let .fulfilled(value) = self {
            return value
        }
        return nil
    }
    
    var error: Error? {
        if case let .rejected(error) = self {
            return error
        }
        return nil
    }


    var description: String {
        switch self {
        case .fulfilled(let value):
            return "Fulfilled (\(value))"
        case .rejected(let error):
            return "Rejected (\(error))"
        case .pending:
            return "Pending"
        }
    }
}


public final class Promise<Value> {
    
    private var state: State<Value>
    private let lockQueue = DispatchQueue(label: "promise_lock_queue", qos: .userInitiated)
    
    /// Creates a Promise in the pending state which can be fulfilled or rejected.
    public init() {
        state = .pending(callbacks: [])
    }
    
    /// Creates a Promise that is immediately fulfilled.
    /// - Parameter value: Result of this Promise
    public init(value: Value) {
        state = .fulfilled(value: value)
    }
    
    /// Creates a Promise that is immediately rejected.
    /// - Parameter error: Result of this Promise
    public init(error: Error) {
        state = .rejected(error: error)
    }
    
    /// Typical Promise intializer. Initializes this Promise with a block
    /// of work to be performed, and allows that closure to either fulfill
    /// or reject the promise.
    /// - Parameters:
    ///   - queue: Optional; queue to perform the work on. Defaults to the
    ///            global queue with the `.userInitiated` quality of service.
    ///   - work: Work to be performed. If the work is succesful, pass the
    ///           result to `fulfill()` closure. If the work fails, pass the
    ///           error to `reject()`.
    ///   - fulfill: Fulfills this promise with the given value.
    ///   - reject: Rejects this promise with the given error.
    ///
    /// Promises are *fulfilled* if they complete successfully with a value
    /// of the type of the Promise. A `Promise<String>` is *fulfilled* if it
    /// generates a `String`.
    ///
    /// Promises are *rejected* if they fail, and thus, generate an `Error`.
    /// With this library, any Promise can produce any `Error`
    public convenience init(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated), work: @escaping (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) throws -> Void) {
        self.init()
        queue.async(execute: {
            do {
                try work(self.fulfill, self.reject)
            } catch let error {
                self.reject(error)
            }
        })
    }

    ///  Converts the result of this promise to a new value
    ///  of type `NewValue` by returning a `Promise<NewValue>`
    ///
    /// - Parameter queue: Optional; queue to perform the work on.
    ///                    Defaults to the main queue.
    /// - Parameter onFulfilled: Transform to perform if this closure fulfills.
    /// - Returns: `Promise<NewValue>`
    ///
    /// This is roughly the equivalent of a traditional `flatMap()`.
    @discardableResult
    public func then<NewValue>(on queue: ExecutionContext = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {
        return Promise<NewValue>(work: { fulfill, reject in
            self.addCallbacks(
                on: queue,
                onFulfilled: { value in
                    do {
                        try onFulfilled(value).then(on: queue, fulfill, reject)
                    } catch let error {
                        reject(error)
                    }
                },
                onRejected: reject
            )
        })
    }
    
    /// Converts the result of this promise to a new value
    /// of type `NewValue` by returning an instance of `NewValue`.
    ///
    /// - Parameters:
    ///   - queue: Optional; queue to perform the work on.
    ///            Defaults to the main queue.
    ///   - onFulfilled: Transform to perform if this closure fulfills.
    /// - Returns: `Promise<NewValue>`
    ///
    /// This is roughly the equivalent of a traditional `map()`.
    @discardableResult
    public func then<NewValue>(on queue: ExecutionContext = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {
        return then(on: queue, { (value) -> Promise<NewValue> in
            do {
                return Promise<NewValue>(value: try onFulfilled(value))
            } catch let error {
                return Promise<NewValue>(error: error)
            }
        })
    }
    
    /// Handles the completion of a Promise.
    /// - Parameters:
    ///   - queue: Optional; queue to perform this work on.
    ///            Defaults to the main queue.
    ///   - onFulfilled: Work to perform if the Promise is fulfilled (completes with a value)
    ///   - onRejected: Work to perform if the Promise is rejected (completes with an error)
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    @discardableResult
    public func then(on queue: ExecutionContext = DispatchQueue.main, _ onFulfilled: @escaping (Value) -> Void, _ onRejected: @escaping (Error) -> Void = { _ in }) -> Promise<Value> {
        addCallbacks(on: queue, onFulfilled: onFulfilled, onRejected: onRejected)
        return self
    }
    
    /// Catches an error if this promise chain is rejected and performs some work.
    /// - Parameters:
    ///   - queue: Optional; queue to perform this work on.
    ///            Defaults to the main queue.
    ///   - onRejected: Work to perform if this promise chain is rejected.
    /// - Returns: A discardable instance of this promise that can be used for further chaining.
    @discardableResult
    public func `catch`(on queue: ExecutionContext = DispatchQueue.main, _ onRejected: @escaping (Error) -> Void) -> Promise<Value> {
        return then(on: queue, { _ in }, onRejected)
    }
    
    /// Rejects this Promise (completes it with an `Error`).
    /// - Parameter error: Error to reject with
    public func reject(_ error: Error) {
        updateState(.rejected(error: error))
    }
    
    /// Fulfills this Promise (completes it succesfully with an instance of `Value`).
    /// - Parameter value: Instance of `Value` to fulfill with
    public func fulfill(_ value: Value) {
        updateState(.fulfilled(value: value))
    }
    
    /// A flag indicating if the promise is still pending.
    public var isPending: Bool {
        return !isFulfilled && !isRejected
    }
    
    /// A flag indicating if the promise is fulfilled (completed successfully).
    public var isFulfilled: Bool {
        return value != nil
    }
    
    /// A flag indicating if the promise is rejected (completed with failure).
    public var isRejected: Bool {
        return error != nil
    }
    
    /// The value that the promise was fulfilled with, if it was fulfilled. `nil` otherwise.
    public var value: Value? {
        return lockQueue.sync(execute: {
            return self.state.value
        })
    }
    
    /// The `Error` that the promise was rejected with, if it was rejected. `nil` otherwise.
    public var error: Error? {
        return lockQueue.sync(execute: {
            return self.state.error
        })
    }
    
    private func updateState(_ newState: State<Value>) {
        lockQueue.async(execute: {
            guard case .pending(let callbacks) = self.state else { return }
            self.state = newState
            self.fireIfCompleted(callbacks: callbacks)
        })
    }
    
    private func addCallbacks(on queue: ExecutionContext = DispatchQueue.main, onFulfilled: @escaping (Value) -> Void, onRejected: @escaping (Error) -> Void) {
        let callback = Callback(onFulfilled: onFulfilled, onRejected: onRejected, executionContext: queue)
        lockQueue.async(flags: .barrier, execute: {
            switch self.state {
            case .pending(let callbacks):
                self.state = .pending(callbacks: callbacks + [callback])
            case .fulfilled(let value):
                callback.callFulfill(value)
            case .rejected(let error):
                callback.callReject(error)
            }
        })
    }
    
    private func fireIfCompleted(callbacks: [Callback<Value>]) {
        guard !callbacks.isEmpty else {
            return
        }
        lockQueue.async(execute: {
            switch self.state {
            case .pending:
                break
            case let .fulfilled(value):
                var mutableCallbacks = callbacks
                let firstCallback = mutableCallbacks.removeFirst()
                firstCallback.callFulfill(value, completion: {
                    self.fireIfCompleted(callbacks: mutableCallbacks)
                })
            case let .rejected(error):
                var mutableCallbacks = callbacks
                let firstCallback = mutableCallbacks.removeFirst()
                firstCallback.callReject(error, completion: {
                    self.fireIfCompleted(callbacks: mutableCallbacks)
                })
            }
        })
    }
}
