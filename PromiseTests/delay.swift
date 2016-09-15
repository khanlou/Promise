//
//  delay.swift
//  Promise
//
//  Created by Soroush Khanlou on 8/2/16.
//
//

import XCTest

internal func delay(_ duration: TimeInterval, block: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
        block()
    })
}


struct SimpleError: Error, Equatable {
    
}


func ==(lhs: SimpleError, rhs: SimpleError) -> Bool {
    return true
}
