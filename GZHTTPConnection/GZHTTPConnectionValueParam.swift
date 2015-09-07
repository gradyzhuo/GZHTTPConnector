//
//  GZHTTPConnectionDataParam.swift
//  Flingy
//
//  Created by Grady Zhuo on 2/27/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import UIKit

class GZHTTPConnectionValueParam{
    var type:GZHTTPConnectionParamType{
        return .String
    }
    var key:String
    var value:AnyObject
    
    init(key:String, value:AnyObject){
        
        self.key = key
        self.value = value as AnyObject
        
    }
    
}

class GZHTTPConnectionStringValueParam: GZHTTPConnectionValueParam {
    //Empty
    
    init(key:String, stringValue:String){
        
        super.init(key: key, value: stringValue)
    }
    
}

//class GZHTTPConnectionArrayPartValueParam: GZHTTPConnectionValueParam {
//    //Empty
//    
//    init(key:String, arrayValue:[AnyObject]){
//        super.init(key: key, value: arrayValue)
//    }
//    
//}

class GZHTTPConnectionFileValueParam: GZHTTPConnectionValueParam {
    
    override var type:GZHTTPConnectionParamType{
        return .File
    }
    
    var filenmae = "Default"
    var contentType:GZHTTPConnectionFileContentType = .All
    
    init(key: String, fileData: NSData) {
        super.init(key: key, value: fileData)
        
    }
    
    convenience init(filename:String, key: String, fileData: NSData) {
        self.init(contentType:.All, filename:filename, key: key, fileData: fileData)
    }
    
    convenience init(contentType:GZHTTPConnectionFileContentType, filename:String, key: String, fileData: NSData) {
        self.init(key: key, fileData: fileData)
        
        self.filenmae = filename
        self.contentType = contentType
        
    }
    
}

class GZHTTPConnectionImageDataValueParam: GZHTTPConnectionFileValueParam {
    
    override var type:GZHTTPConnectionParamType{
        return .File
    }
    
    override init(key: String, fileData: NSData) {
        super.init(key: key, fileData: fileData)
        
        self.contentType = .JPEG
        
    }
    
}


//MARK: - add params
extension GZHTTPConnectionData {
    
    func addParam(param:GZHTTPConnectionValueParam){
        self.paramsArray.append(param)
    }
    
    func addParam(key key:String, boolValue value:Bool?)->GZHTTPConnectionValueParam{
        let defaultValue = false
        return self.addParam(key: key, intValue: Int(value ?? defaultValue))
    }
    
    func addParam(key key:String, intValue value:Int?)->GZHTTPConnectionValueParam{
        let defaultValue = 0
        let stringValue = "\(value ?? defaultValue)"
        return self.addParam(key: key, stringValue: stringValue)
    }
    
    func addParam(key key:String, stringValue value:String?)->GZHTTPConnectionValueParam{
        let defaultValue = ""
        let param = GZHTTPConnectionStringValueParam(key: key, stringValue: value ?? defaultValue)
        self.addParam(param)
        return param
    }
    
    func addParam(key key:String, stringValueFromArray value:[AnyObject]?, componentsJoinedByString separator:String = ",")->GZHTTPConnectionValueParam{
        return self += key & (value ?? []) << separator
    }
    
    //MARK: - file handler
    func addParam(key key:String, fileData value:NSData?, contentType:GZHTTPConnectionFileContentType, filename:String)->GZHTTPConnectionValueParam{
        let defaultValue = NSData()
        let param = GZHTTPConnectionImageDataValueParam(contentType: contentType, filename: filename, key: key, fileData: value ?? defaultValue)
        self.addParam(param)
        return param
    }
    
    func addAnyFileDataValueParam(key key:String, fileData value:NSData?, filename:String)->GZHTTPConnectionValueParam{
        return self.addParam(key: key, fileData: value, contentType: .All, filename: filename)
    }
    
    //MARK: image handler
    func addJPEGImageDataValueParam(key key:String, fileData value:NSData?, filename:String)->GZHTTPConnectionValueParam{
        return self.addParam(key: key, fileData: value, contentType: .JPEG, filename: filename)
    }
    
    func addJPEGImageDataValueParam(key key:String, image:UIImage!, filename:String, compressionQuality:CGFloat)->GZHTTPConnectionValueParam{
        
        let data = UIImageJPEGRepresentation(image, compressionQuality)
        return self.addJPEGImageDataValueParam(key: key, fileData: data, filename: filename)
        
    }
    
    func addPNGImageDataValueParam(key key:String, fileData value:NSData?, filename:String)->GZHTTPConnectionValueParam{
        return self.addParam(key: key, fileData: value, contentType: .PNG, filename: filename)
    }
    
    func addPNGImageDataValueParam(key key:String, image:UIImage!, filename:String)->GZHTTPConnectionValueParam{
        
        let data = UIImagePNGRepresentation(image)
        return self.addPNGImageDataValueParam(key: key, fileData: data, filename: filename)
        
    }
    
}


//MARK: - remove param
extension GZHTTPConnectionData {
    
    func removeParam(forKey key:String){
        self.paramsArray = self.paramsArray.filter{ return $0.key != key }
    }
    
    func removeParam(param:GZHTTPConnectionValueParam){
        self.removeParam(forKey: param.key)
    }
    
}

