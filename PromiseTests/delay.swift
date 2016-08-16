//
//  delay.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/2/16.
//
//

import XCTest

internal func delay(_ duration: TimeInterval, block: @escaping () -> ()) {
    let time = DispatchTime.now() + Double(Int64(duration*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: time, execute: {
        block()
    })
}


struct SimpleError: Error, Equatable {
    
}


func ==(lhs: SimpleError, rhs: SimpleError) -> Bool {
    return true
}
