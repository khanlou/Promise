//
//  Promise.h
//  Promise
//
//  Created by Soroush Khanlou on 8/1/16.
//
//

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
@import UIKit;
#else
@import AppKit;
#endif

//! Project version number for Promise.
FOUNDATION_EXPORT double PromiseVersionNumber;

//! Project version string for Promise.
FOUNDATION_EXPORT const unsigned char PromiseVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Promise/PublicHeader.h>


