//
//  delay.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/2/16.
//
//

import XCTest

internal func delay(duration: NSTimeInterval, block: () -> ()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(duration*Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), {
        block()
    })
}


struct SimpleError: ErrorType, Equatable {
    
}


func ==(lhs: SimpleError, rhs: SimpleError) -> Bool {
    return true
}
