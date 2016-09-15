//
//  Promise.swift
//  Promise
//
//  Created by Soroush Khanlou on 7/21/16.
//
//

import Foundation

struct Callback<Value> {
    let onFulfilled: (Value -> ())
    let onRejected: (ErrorType -> ())
    let queue: dispatch_queue_t
    
    func callFulfill(value: Value) {
        dispatch_async(queue, {
            self.onFulfilled(value)
        })
    }
    
    func callReject(error: ErrorType) {
        dispatch_async(queue, {
            self.onRejected(error)
        })
    }
}

enum State<Value>: CustomStringConvertible {
    case Pending
    case Fulfilled(value: Value)
    case Rejected(error: ErrorType)
    
    var isPending: Bool {
        if case .Pending = self {
            return true
        } else {
            return false
        }
    }
    
    var isFulfilled: Bool {
        if case .Fulfilled = self {
            return true
        } else {
            return false
        }
    }
    
    var isRejected: Bool {
        if case .Rejected = self {
            return true
        } else {
            return false
        }
    }
    
    var value: Value? {
        if case let .Fulfilled(value) = self {
            return value
        }
        return nil
    }
    
    var error: ErrorType? {
        if case let .Rejected(error) = self {
            return error
        }
        return nil
    }

    
    var description: String {
        switch self {
        case .Fulfilled(let value):
            return "Fulfilled (\(value))"
        case .Rejected(let error):
            return "Rejected (\(error))"
        case .Pending:
            return "Pending"
        }
    }
}


final class Promise<Value> {
    
    private var state: State<Value>
    private let lockQueue = dispatch_queue_create("lock_queue", DISPATCH_QUEUE_SERIAL)
    private var callbacks: [Callback<Value>] = []
    
    init() {
        state = .Pending
    }
    
    init(value: Value) {
        state = .Fulfilled(value: value)
    }
    
    init(error: ErrorType) {
        state = .Rejected(error: error)
    }
    
    convenience init(queue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), work: (fulfill: (Value) -> (), reject: (ErrorType) -> () ) -> ()) {
        self.init()
        dispatch_async(queue, {
            work(fulfill: self.fulfill, reject: self.reject)
        })
    }
    
    func then<NewValue>(on queue: dispatch_queue_t = dispatch_get_main_queue(), _ onFulfilled: ((Value) -> Promise<NewValue>)) -> Promise<NewValue> {
        //this one is flatmap
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
    
    func then<NewValue>(on queue: dispatch_queue_t = dispatch_get_main_queue(), _ onFulfilled: ((Value) throws -> NewValue)) -> Promise<NewValue> {
        //this one is map
        return then(on: queue, { (value) -> Promise<NewValue> in
            do {
                return Promise<NewValue>(value: try onFulfilled(value))
            } catch let error {
                return Promise<NewValue>(error: error)
            }
        })
    }
    
    func then(on queue: dispatch_queue_t = dispatch_get_main_queue(), _ onFulfilled: (Value -> Void), _ onRejected: ErrorType -> Void) -> Promise<Value> {
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
    
    func then(on queue: dispatch_queue_t = dispatch_get_main_queue(), _ onFulfilled: (Value -> Void)) -> Promise<Value> {
        return then(on: queue, onFulfilled, { _ in })
    }
    
    func onFailure(on queue: dispatch_queue_t, _ onRejected: ErrorType -> Void) -> Promise<Value> {
        return then(on: queue, { _ in }, onRejected)
    }
    
    func onFailure(onRejected: ErrorType -> Void) -> Promise<Value> {
        return then(on: dispatch_get_main_queue(), { _ in }, onRejected)
    }
    
    func reject(error: ErrorType) {
        updateState(.Rejected(error: error))
    }
    
    func fulfill(value: Value) {
        updateState(.Fulfilled(value: value))
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
        dispatch_sync(lockQueue, {
            result = self.state.value
        })
        return result
    }
    
    var error: ErrorType? {
        var result: ErrorType?
        dispatch_sync(lockQueue, {
            result = self.state.error
        })
        return result
    }
    
    private func updateState(state: State<Value>) {
        guard self.isPending else { return }
        dispatch_sync(lockQueue, {
            self.state = state
        })
        fireCallbacksIfCompleted()
    }
    
    private func addCallbacks(on queue: dispatch_queue_t, onFulfilled: (Value -> Void), onRejected: ErrorType -> Void) {
        let callback = Callback(onFulfilled: onFulfilled, onRejected: onRejected, queue: queue)
        dispatch_async(lockQueue) {
            self.callbacks.append(callback)
        }
        fireCallbacksIfCompleted()
    }
    
    private func fireCallbacksIfCompleted() {
        dispatch_async(lockQueue) {
            guard !self.state.isPending else { return }
            self.callbacks.forEach { callback in
                switch self.state {
                case let .Fulfilled(value):
                    callback.callFulfill(value)
                case let .Rejected(error):
                    callback.callReject(error)
                default:
                    break
                }
            }
            self.callbacks.removeAll()
        }
    }
}
