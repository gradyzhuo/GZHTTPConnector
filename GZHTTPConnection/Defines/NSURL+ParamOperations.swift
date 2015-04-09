//
//  NSURL+ParamOperations.swift
//  Flingy
//
//  Created by Grady Zhuo on 2/27/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import Foundation


extension NSURL{
    
    func parametersDictionary() -> [String:String]{
        
        var md:[String:String] = [String:String]()
        var components:NSURLComponents! = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)
        
        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("8.0"){
            
            for obj in components.queryItems! {
                
                var query = obj as! NSURLQueryItem
                
                md[query.name] = query.value
                
            }
            
        }else{
            if let query = components.query {
                
                var items = query.componentsSeparatedByString("&")
                
                for item in items {
                    
                    var queryItem = item.componentsSeparatedByString("=")
                    
                    if queryItem.count > 2 || queryItem.count == 0 {
                        continue
                    }
                    
                    md[queryItem.first! as String] = queryItem.last! as String
                    
                }
            }
            
            
        }
        
        
        return md
        
    }
}
