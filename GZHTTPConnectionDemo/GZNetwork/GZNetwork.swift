//
//  GZNetwork.swift
//  GZHTTPConnectionDemo
//
//  Created by Grady Zhuo on 3/14/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import Foundation


public class GZHTTPConnection:NSObject {
    
    internal var privateObjectInfo:ObjectInfo = ObjectInfo()
    
    internal let reachability:Reachability = Reachability.reachabilityForInternetConnection()
    
    public var hostURL:NSURL?
    
    public var delegateQueue:NSOperationQueue = NSOperationQueue.mainQueue()
    
    //    lazy var backgroundSession:NSURLSession = {
    //        var timeStamp = NSDate().timeIntervalSince1970
    //        var configuration = NSURLSessionConfiguration.backgroundSessionConfiguration("com.offsky.connection.backgroundMode.\(timeStamp)")
    //        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: self.delegateQueue)
    //    }()
    
    public override convenience init() {
        var hostURL = GZHTTPConnection.hostURLFromInfoDictionary()
        self.init(hostURL:hostURL)
    }
    
    public init(hostURL:NSURL?){
        super.init()
        
        self.hostURL = hostURL
        self.reachability.startNotifier()
        self.privateObjectInfo.session = NSURLSession.sharedSession()
    }
    
    public convenience init(hostURL:NSURL, session:NSURLSession){
        self.init(hostURL:hostURL)
        
        self.privateObjectInfo.session = session
        
    }
    
    public convenience init(hostURL:NSURL, sessionConfiguration configuration: NSURLSessionConfiguration?, sessionDelegate delegate:NSURLSessionDelegate?, delegateQueue queue:NSOperationQueue?){
        
        var session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
        self.init(hostURL:hostURL, session:session)
        
    }
    
}


// MARK: - GZHTTPConnectionData

public class GZHTTPConnectionData:NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate{
    
    var session:NSURLSession?{
        return self.privateObjectInfo.session
    }
    
    var sessionConfiguration:NSURLSessionConfiguration?
    
    var sessionDataTask:NSURLSessionTask?{
        get{
            return self.privateObjectInfo.sessionTask
        }
    }
    
    var sessionDelegateQueue:NSOperationQueue?
    
    var paramsArray:[GZHTTPConnectionValueParam] = []
    
    var finalParams:[GZHTTPConnectionValueParam] {
        return self.privateObjectInfo.finalParamsArrayForConnection
    }
    
    var HTTPMethod:GZHTTPConnectionDataMethod{
        get{
            return GZHTTPConnectionDataMethod.GET
        }
    }
    
    var inputValueType:GZHTTPConnectionInputValueType{
        get{
            return GZHTTPConnectionInputValueType.KeyValue
        }
    }
    
    var outputValueType:GZHTTPConnectionOutputValueType{
        get{
            return GZHTTPConnectionOutputValueType.JSON
        }
    }
    
    var timeoutInterval:NSTimeInterval = 30
    
    var dependedConnectorDatas : [GZHTTPConnectionData] = [GZHTTPConnectionData]()
    
    var removeDuplicatedKeysInDependedDatas:Bool = true
    
    var extraHeaderFields:[String:String] = [:]
    
    //    var boundary:String = ""
    
    internal var privateObjectInfo = ObjectInfo()
    
}
