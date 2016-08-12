//
//  Promise+Extras.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/3/16.
//
//

import Foundation

extension Promise {
    static func all<T>(promises: [Promise<T>]) -> Promise<[T]> {
        return Promise<[T]>(work: { fulfill, reject in
            guard !promises.isEmpty else { fulfill([]); return }
            for promise in promises {
                promise.then({ value in
                    if !promises.contains({ $0.isRejected || $0.isPending }) {
                        fulfill(promises.flatMap({ $0.value }))
                    }
                }).onFailure({ error in
                    reject(error)
                })
            }
        })
    }

    static func delay(delay: NSTimeInterval) -> Promise<()> {
        return Promise<()>(work: { fulfill, reject in
            let nanoseconds = Int64(delay*Double(NSEC_PER_SEC))
            let time = dispatch_time(DISPATCH_TIME_NOW, nanoseconds)
            dispatch_after(time, dispatch_get_main_queue(), {
                fulfill(())
            })
        })
    }
}
