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
    var completion: () -> Void
    
    func callFulfill(_ value: Value) {
        executionContext.execute({
            self.onFulfilled(value)
            self.completion()
        })
    }
    
    func callReject(_ error: Error) {
        executionContext.execute({
            self.onRejected(error)
            self.completion()
        })
    }
}

enum State<Value>: CustomStringConvertible {

    /// The promise has not completed yet.
    /// Will transition to either the `fulfilled` or `rejected` state.
    case pending

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
    private var callbacks: [Callback<Value>] = []
    
    public init() {
        state = .pending
    }
    
    public init(value: Value) {
        state = .fulfilled(value: value)
    }
    
    public init(error: Error) {
        state = .rejected(error: error)
    }
    
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

    /// - note: This one is "flatMap"
    @discardableResult
    public func then<NewValue>(on queue: ExecutionContext = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {
        return Promise<NewValue>(work: { fulfill, reject in
            self.addCallbacks(
                on: queue,
                onFulfilled: { value in
                    do {
                        try onFulfilled(value).then(on: queue, fulfill, reject)
                    } catch {
                        reject(error)
                    }
                },
                onRejected: reject
            )
        })
    }
    
    /// - note: This one is "map"
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
    
    @discardableResult
    public func then(on queue: ExecutionContext = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> Void) -> Promise<Value> {
        return Promise(work: { (fulfill, reject) in
            self.addCallbacks(on: queue, onFulfilled: { (value) in
                do {
                    try onFulfilled(value)
                    fulfill(value)
                } catch {
                    reject(error)
                }
            }, onRejected: reject)
        })
    }
    
    @discardableResult
    func then(on queue: ExecutionContext = DispatchQueue.main, _ onFulfilled: @escaping (Value) -> Void, _ onRejected: @escaping (Error) -> Void) -> Promise<Value> {
        addCallbacks(on: queue, onFulfilled: onFulfilled, onRejected: onRejected)
        return self
    }
    
    @discardableResult
    public func `catch`(on queue: ExecutionContext = DispatchQueue.main, _ onRejected: @escaping (Error) -> Void) -> Promise<Value> {
        return then(on: queue, { _ in }, onRejected)
    }
    
    public func reject(_ error: Error) {
        updateState(.rejected(error: error))
    }
    
    public func fulfill(_ value: Value) {
        updateState(.fulfilled(value: value))
    }
    
    public var isPending: Bool {
        return !isFulfilled && !isRejected
    }
    
    public var isFulfilled: Bool {
        return value != nil
    }
    
    public var isRejected: Bool {
        return error != nil
    }
    
    public var value: Value? {
        return lockQueue.sync(execute: {
            return self.state.value
        })
    }
    
    public var error: Error? {
        return lockQueue.sync(execute: {
            return self.state.error
        })
    }
    
    private func updateState(_ state: State<Value>) {
        guard self.isPending else { return }
        lockQueue.sync(execute: {
            self.state = state
        })
        fireCallbacksIfCompleted()
    }
    
    private func addCallbacks(on queue: ExecutionContext = DispatchQueue.main, onFulfilled: @escaping (Value) -> Void, onRejected: @escaping (Error) -> Void) {
        let callback = Callback(onFulfilled: onFulfilled, onRejected: onRejected, executionContext: queue) {
            self.fireCallbacksIfCompleted()
        }
        lockQueue.async(execute: {
            self.callbacks.append(callback)
        })
        fireCallbacksIfCompleted()
    }
    
    private func fireCallbacksIfCompleted() {
        lockQueue.async(execute: {
            guard let callback = self.callbacks.first, !self.state.isPending else {
                return
            }
            self.callbacks.removeFirst()

            switch self.state {
            case let .fulfilled(value):
                callback.executionContext.execute {
                    callback.callFulfill(value)
                }
            case let .rejected(error):
                callback.executionContext.execute {
                    callback.callReject(error)
                }
            default:
                break
            }
            
        })
    }
}
