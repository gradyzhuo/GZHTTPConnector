//
//  VersionCheck.swift
//  Flingy
//
//  Created by Grady Zhuo on 2014/10/2.
//  Copyright (c) 2014年 Grady Zhuo. All rights reserved.
//

import Foundation

func SYSTEM_VERSION_EQUAL_TO(version: NSString) -> Bool {
    
    return UIDevice.currentDevice().systemVersion.compare(version,
        options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedSame
}

func SYSTEM_VERSION_GREATER_THAN(version: NSString) -> Bool {
    return UIDevice.currentDevice().systemVersion.compare(version,
        options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedDescending
}

func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(version: NSString) -> Bool {
    return UIDevice.currentDevice().systemVersion.compare(version,
        options: NSStringCompareOptions.NumericSearch) != NSComparisonResult.OrderedAscending
}

func SYSTEM_VERSION_LESS_THAN(version: NSString) -> Bool {
    return UIDevice.currentDevice().systemVersion.compare(version,
        options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedAscending
}

func SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(version: NSString) -> Bool {
    return UIDevice.currentDevice().systemVersion.compare(version,
        options: NSStringCompareOptions.NumericSearch) != NSComparisonResult.OrderedDescending
}