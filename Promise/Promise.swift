//
//  Promise.swift
//  Promise
//
//  Created by Soroush Khanlou on 7/21/16.
//
//

import Foundation

struct Callback<Value> {
    let onFulfilled: (Value) -> ()
    let onRejected: (Error) -> ()
    let queue: DispatchQueue
    
    func callFulfill(_ value: Value) {
        queue.async(execute: {
            self.onFulfilled(value)
        })
    }
    
    func callReject(_ error: Error) {
        queue.async(execute: {
            self.onRejected(error)
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


final class Promise<Value> {
    
    private var state: State<Value>
    private let lockQueue = DispatchQueue(label: "promise_lock_queue", qos: .userInitiated)
    private var callbacks: [Callback<Value>] = []
    
    init() {
        state = .pending
    }
    
    init(value: Value) {
        state = .fulfilled(value: value)
    }
    
    init(error: Error) {
        state = .rejected(error: error)
    }
    
    convenience init(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated), work: @escaping (_ fulfill: @escaping (Value) -> (), _ reject: @escaping (Error) -> () ) -> ()) {
        self.init()
        queue.async(execute: {
            work(self.fulfill, self.reject)
        })
    }

    /// - note: This one is "flatMap"
    @discardableResult
    func then<NewValue>(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (Value) -> Promise<NewValue>) -> Promise<NewValue> {
        return Promise<NewValue>(work: { fulfill, reject in
            self.addCallbacks(
                on: queue,
                onFulfilled: { value in
                    onFulfilled(value).then(fulfill, reject)
                },
                onRejected: reject
            )
        })
    }
    
    /// - note: This one is "map"
    @discardableResult
    func then<NewValue>(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (Value) -> NewValue) -> Promise<NewValue> {
        return then(on: queue, { (value) -> Promise<NewValue> in
            return Promise<NewValue>(value: onFulfilled(value))
        })
    }
    
    @discardableResult
    func then(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (Value) -> (), _ onRejected: @escaping (Error) -> ()) -> Promise<Value> {
        return Promise<Value>(work: { fulfill, reject in
            self.addCallbacks(
                on: queue,
                onFulfilled: { value in
                    fulfill(value)
                    onFulfilled(value)
                },
                onRejected: { error in
                    reject(error)
                    onRejected(error)
                }
            )
        })
    }

    @discardableResult
    func then(on queue: DispatchQueue = DispatchQueue.main, _ onFulfilled: @escaping (Value) -> ()) -> Promise<Value> {
        return then(on: queue, onFulfilled, { _ in })
    }
    
    func onFailure(on queue: DispatchQueue, _ onRejected: @escaping (Error) -> ()) -> Promise<Value> {
        return then(on: queue, { _ in }, onRejected)
    }
    
    @discardableResult
    func onFailure(_ onRejected: @escaping (Error) -> ()) -> Promise<Value> {
        return then(on: DispatchQueue.main, { _ in }, onRejected)
    }
    
    func reject(_ error: Error) {
        updateState(.rejected(error: error))
    }
    
    func fulfill(_ value: Value) {
        updateState(.fulfilled(value: value))
    }
    
    var isPending: Bool {
        return !isFulfilled && !isRejected
    }
    
    var isFulfilled: Bool {
        return value != nil
    }
    
    var isRejected: Bool {
        return error != nil
    }
    
    var value: Value? {
        var result: Value?
        lockQueue.sync(execute: {
            result = self.state.value
        })
        return result
    }
    
    var error: Error? {
        var result: Error?
        lockQueue.sync(execute: {
            result = self.state.error
        })
        return result
    }
    
    private func updateState(_ state: State<Value>) {
        guard self.isPending else { return }
        lockQueue.sync(execute: {
            self.state = state
        })
        fireCallbacksIfCompleted()
    }
    
    private func addCallbacks(on queue: DispatchQueue, onFulfilled: @escaping (Value) -> (), onRejected: @escaping (Error) -> ()) {
        let callback = Callback(onFulfilled: onFulfilled, onRejected: onRejected, queue: queue)
        lockQueue.async(execute: {
            self.callbacks.append(callback)
        })
        fireCallbacksIfCompleted()
    }
    
    private func fireCallbacksIfCompleted() {
        lockQueue.async(execute: {
            guard !self.state.isPending else { return }
            self.callbacks.forEach { callback in
                switch self.state {
                case let .fulfilled(value):
                    callback.callFulfill(value)
                case let .rejected(error):
                    callback.callReject(error)
                default:
                    break
                }
            }
            self.callbacks.removeAll()
        })
    }
}
