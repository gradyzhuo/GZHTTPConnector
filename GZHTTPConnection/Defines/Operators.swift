//
//!  Operators.swift
//  Flingy
//
//  Created by Grady Zhuo on 3/13/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import UIKit

protocol GZHTTPConnectionParamValueType{}
protocol GZHTTPConnectionParamBasicType:GZHTTPConnectionParamValueType{}

extension Int : GZHTTPConnectionParamBasicType {}
extension Bool : GZHTTPConnectionParamBasicType {}
extension String : GZHTTPConnectionParamBasicType {}

extension NSData : GZHTTPConnectionParamValueType {}
extension UIImage : GZHTTPConnectionParamValueType {}


//infix operator + { precedence 50 }
//infix operator & { precedence 60 }
infix operator << { precedence 160 }


func <<(value:[AnyObject], separator:String)->String{
    
    var str : String = ""
    for (idx, item) in enumerate(value) {
        str += "\(item)"
        if idx < value.count-1 {
            str += separator
        }
    }
    
    return str
}


func &(key:String, getValue: ()->String)(connectionData:GZHTTPConnectionData)->GZHTTPConnectionValueParam{
    return connectionData.addParam(key: key, stringValue: getValue())
}

func &(key:String, @autoclosure getValue: ()->GZHTTPConnectionParamBasicType)(connectionData:GZHTTPConnectionData)->GZHTTPConnectionValueParam{
    
    var value = getValue()
    
    switch value {
    case let intValue as Int:
        return connectionData.addParam(key: key, intValue: intValue)
    case let boolValue as Bool:
        return connectionData.addParam(key: key, boolValue: boolValue)
    case let stringValue as String:
        return connectionData.addParam(key: key, stringValue: stringValue)
    default:
        return connectionData.addParam(key: key, stringValue: "\(value)")
    }
    
}

func += (connectionData:GZHTTPConnectionData, right:(key:GZHTTPConnectionData)->GZHTTPConnectionValueParam)->GZHTTPConnectionValueParam{
    return right(key:connectionData)
}

func + (connectionData:GZHTTPConnectionData, right:[String:GZHTTPConnectionParamBasicType]){
    
    for keyValue in right{
        connectionData + keyValue
    }
    
}

func + (connectionData:GZHTTPConnectionData, right:(String, GZHTTPConnectionParamBasicType)){
    let (key, value) = right
    connectionData += key & value
}


//MARK: - operator '+'

//! now can add GZHTTPConnectionValueParam to GZHTTPConnectionData by syntax [GZHTTPConnectionData] + [GZHTTPConnectionValueParam]

func + (left:GZHTTPConnectionData, right:GZHTTPConnectionValueParam)->GZHTTPConnectionData{
    left.addParam(right)
    return left
}




//public func + (left:GZHTTPConnectionData, right:GZHTTPConnectionValueParam)->Void{
//    left.addParam(right)
//}
