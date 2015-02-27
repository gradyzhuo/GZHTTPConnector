//
//  Enumeration.swift
//  Flingy
//
//  Created by Grady Zhuo on 2/27/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import Foundation

//MARK: - GZHTTPConnectionData Enums
enum GZHTTPConnectionDataMethod:String{
    case POST = "POST"
    case GET = "GET"
    case PUT = "PUT"
    case DELETE = "DELETE"
}


enum GZHTTPConnectionInputValueType{
    case JSON, KeyValue
    /** Uploading file and give a 'Boundary'. Params format: .FileUpload( Boundary:String )  */
    case FileUpload(boundary:String)
}

enum GZHTTPConnectionOutputValueType:Int{
    case JSON, Image, HTML, XML, Text, OriginalData
}

enum GZHTTPConnectionParamType:Int{
    case File, String
}

enum GZHTTPConnectionFileContentType:String{
    case None = "none/none"
    case All = "application/octet-stream"
    case JPEG = "image/jpeg"
    case PNG = "image/png"
}