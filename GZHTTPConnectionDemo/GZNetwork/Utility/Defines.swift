//
//  Defines.swift
//  Flingy
//
//  Created by Grady Zhuo on 2014/10/3.
//  Copyright (c) 2014年 Grady Zhuo. All rights reserved.
//

import Foundation



func GZDebugLog() {
    #if DEBUG
        println("[DEBUG]")
    #endif
}

func GZDebugLog(object:AnyObject!) {
    
    #if DEBUG
        println("[DEBUG]:\(object)")
    #endif
    
}

func GZReportLog(object:AnyObject!){
    #if !DEBUG
//        IBGLog("[REPORT]:\(object)")
    #endif
}
