//
//  GZHTTPConnection.swift
//  Flingy
//
//  Created by Grady Zhuo on 2014/9/15.
//  Copyright (c) 2014年 Grady Zhuo. All rights reserved.
//

import Foundation


// MARK : CompleteHandler for client-server connection
typealias __GZHTTPConnectionCallBackDefaultCompletionHandler = (obj:AnyObject!, response:NSURLResponse!, error:NSError!) -> Void
typealias __GZHTTPConnectionCallBackDefaultFailHandler = (response:NSURLResponse!, error:NSError!) -> Void

//MARK: DefaultCompleteHandler
typealias GZHTTPConnectionCallBackDefaultCompleteHandler = (obj:AnyObject!, response:NSURLResponse!, error:NSError!) -> Void
typealias GZHTTPConnectionCallBackDefaultFailHandler = (obj:AnyObject!, response:NSURLResponse!, error:NSError!) -> Void

//MARK: DefaultCompleteHandler
typealias GZHTTPConnectionCompleteHandlerCallBackObject = GZHTTPConnectionCallBackDefaultCompleteHandler
typealias GZHTTPConnectionCompleteHandlerCallBackArray = (array:[AnyObject]!, response:NSURLResponse!, error:NSError!) -> Void
typealias GZHTTPConnectionCompleteHandlerCallBackDictionary = (dictionary:[NSObject:AnyObject]!, response:NSURLResponse!, error:NSError!) -> Void
typealias GZHTTPConnectionCompleteHandlerCallBackBoolean = (success:Bool, response:NSURLResponse!, error:NSError!) -> Void




class GZHTTPConnection:NSObject {
    
    let reachability:Reachability = Reachability.reachabilityForInternetConnection()
    var hostURL:NSURL = NSURL()
    
    var delegateQueue:NSOperationQueue = NSOperationQueue.mainQueue()
    
    
    var session:NSURLSession? = nil
    
//    lazy var session:NSURLSession = {
//        
//        var sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
//        sessionConfig.allowsCellularAccess = true
//        
//        var customSession:NSURLSession = NSURLSession(configuration:sessionConfig , delegate: self, delegateQueue: self.delegateQueue)
//        
//        return customSession
//    }()
    
    lazy var backgroundSession:NSURLSession = {
        var timeStamp = NSDate().timeIntervalSince1970
        var configuration = NSURLSessionConfiguration.backgroundSessionConfiguration("com.offsky.connection.backgroundMode.\(timeStamp)")
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: self.delegateQueue)
    }()
    
    override convenience init() {
        self.init(hostURL:NSURL())
    }
    
    init(hostURL:NSURL){
        super.init()
        
        self.hostURL = hostURL
        self.reachability.startNotifier()
        
    }
    
    // MARK: singleton
    class var defaultConnector : GZHTTPConnection! {
        
        dispatch_once(&ObjectInfo.once_token){
            ObjectInfo.sharedInstance = GZHTTPConnection(hostURL: APPCONFIG_API_BASE_URL)
        }
        
        return ObjectInfo.sharedInstance!
    }
    
    var backgroundSessionCompletionHandler:(()->Void)!
    
    convenience init(hostURL:NSURL, session:NSURLSession){
        self.init(hostURL:hostURL)
        
        self.session = session
    }
    
    func isNetworkReachable() -> Bool {
        return self.reachability.currentReachabilityStatus() != NetworkStatus.NotReachable
    }
    
    
    // MARK: default connector
    func defaultConnectionByDefaultHostURL(api:String, connectorData:GZHTTPConnectionData, completionHandler:__GZHTTPConnectionCallBackDefaultCompletionHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)-> NSURLSessionTask?{
        
        var APIURL = self.hostURL.URLByAppendingPathComponent(api)
        
        return self.defaultConnection(url: APIURL, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
        
    }
    
    func defaultConnection(baseURL:NSURL, api:String, connectorData:GZHTTPConnectionData, completionHandler:__GZHTTPConnectionCallBackDefaultCompletionHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)-> NSURLSessionTask?{
        
        var APIURL = baseURL.URLByAppendingPathComponent(api)
        
        return self.defaultConnection(url: APIURL, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
        
    }
    
    
    func defaultConnection(#url:NSURL, connectorData:GZHTTPConnectionData, completionHandler:__GZHTTPConnectionCallBackDefaultCompletionHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)-> NSURLSessionTask?{
        
        var request = NSMutableURLRequest(URL: url)
        
        connectorData.prepare()
        connectorData.recusiveDependedConnectorDatas()
        
        for (k, v) in connectorData.extraHeaderFields {
            request.addValue(v, forHTTPHeaderField: k)
        }
        
        request.timeoutInterval = connectorData.timeoutInterval
        
        switch connectorData.HTTPMethod {
            
        case .GET :
            
            var URLComponents:NSURLComponents! = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
            
            var senderString = connectorData.senderString()
            
            if senderString != "" {
                URLComponents.query = senderString
            }
            
            request.URL = URLComponents.URL!
            
            return self.defaultConnection(request: request, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
            
            
        default://POST Like Methods (POST,PUT,DELETE)

            request.HTTPMethod = connectorData.HTTPMethod.rawValue
            
            switch connectorData.inputValueType {
            case let .FileUpload(boundary):
                var uploadData = connectorData.senderData()
                request.setValue("\(uploadData.length)", forHTTPHeaderField: "Content-Length")
                
                var charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
                var contentType = "multipart/form-data; charset=\(charset); boundary=\(boundary)"
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                
                return self.defaultUploadConnection(request: request, connectorData: connectorData, fromData:uploadData, completionHandler: completionHandler, failHandler: failHandler)
                
            default:
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.HTTPBody = connectorData.senderData()
                
                return self.defaultConnection(request: request, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
                
            }
        }
        
    }
    
    func defaultConnection(#request:NSURLRequest, connectorData:GZHTTPConnectionData , completionHandler:__GZHTTPConnectionCallBackDefaultCompletionHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler) -> NSURLSessionTask? {
        
        var session = self.__prepareConnectionSession(request: request, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
        
        var task:NSURLSessionTask? = session.dataTaskWithRequest(request, completionHandler: { (data:NSData!, response:NSURLResponse!, error:NSError!) -> Void in
            self.connectionCompletionHandler(connectorData, url:request.URL, data: data, response: response, connectionError: error, completionHandler: completionHandler, failHandler: failHandler)
        })

        connectorData.privateCache.sessionTask = task
        connectorData.privateCache.session = session
        
        return task
    }
    
    
    func defaultUploadConnection(#request:NSURLRequest, connectorData:GZHTTPConnectionData, fromData uploadData:NSData!, completionHandler:__GZHTTPConnectionCallBackDefaultCompletionHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)->NSURLSessionTask?{
        
        var session = self.__prepareConnectionSession(request: request, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
        
        connectorData.privateCache.session = session
        
        var task = session.uploadTaskWithRequest(request, fromData:uploadData, completionHandler: { (data:NSData!, response:NSURLResponse!, error:NSError!) -> Void in
            self.connectionCompletionHandler(connectorData, url:request.URL ,data: data, response: response, connectionError: error, completionHandler: completionHandler, failHandler: failHandler)
        })
        
        connectorData.privateCache.sessionTask = task
        
        
        return task
        
    }
    
    
    private func __prepareConnectionSession(#request:NSURLRequest, connectorData:GZHTTPConnectionData, completionHandler:__GZHTTPConnectionCallBackDefaultCompletionHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)->NSURLSession!{
        
        if !self.checkISNetworkReachable(failHandler){
            return nil
        }
        
        self.startConnecting()
        
        var session = self.session
        
        if session == nil {
            connectorData.sessionConfiguration = connectorData.sessionConfiguration ?? NSURLSessionConfiguration.defaultSessionConfiguration()
            connectorData.sessionConfiguration?.allowsCellularAccess = true
            
            connectorData.sessionDelegateQueue = connectorData.sessionDelegateQueue ?? NSOperationQueue.mainQueue()
            
            session = NSURLSession(configuration: connectorData.sessionConfiguration, delegate: connectorData, delegateQueue: connectorData.sessionDelegateQueue)
        }
        
        return session
    }
    
    func connectionCompletionHandler(connectorData:GZHTTPConnectionData!, url:NSURL!, data:NSData!, response:NSURLResponse!, connectionError:NSError!, completionHandler:__GZHTTPConnectionCallBackDefaultCompletionHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler) -> Void{
        
        self.stopConnecting()
        
        var anyError:NSError?
        var resultObject:AnyObject?
        
        if connectionError != nil {
            
            anyError = connectionError
            
            GZDebugLog("[network error] there are some error happened with connection to Server. below is the error message:<\(connectionError.localizedDescription)>")
            
            
        }else{
            
            var obj:AnyObject!
            var error:NSError!

            switch connectorData.outputValueType {
            case .JSON:
                (obj, error) = self.convertToJSON(data)
            case .Image:
                (obj, error) = self.convertToTypeImage(data)
                
            default:
                obj = data
                error = nil
            }
            
            resultObject = obj
            anyError = error
            
        }
        
        
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            if anyError != nil {
                self.handleError(failHandler, url:url, connectionData: connectorData, response: response, error: anyError)
            }else{
                self.handleResult(completionHandler, url:url, obj: resultObject, response: response, error: anyError)
            }
            
        })

    }

}

//MARK: connecting operator
extension GZHTTPConnection{

    internal func startConnecting(){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    internal func stopConnecting(){
        
        self.session?.getTasksWithCompletionHandler { (dataTasks:[AnyObject]!, downloadTasks:[AnyObject]!, uploadTasks:[AnyObject]!) -> Void in
            
            if (dataTasks.count + downloadTasks.count + uploadTasks.count) == 0 {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            
            
        }
        
    }
    
}

extension GZHTTPConnection{
    
    private struct ObjectInfo {
        static var sharedInstance : GZHTTPConnection?
        static var once_token : dispatch_once_t = 0
    }
    
}
extension GZHTTPConnection{
    func checkISNetworkReachable(failHandler:__GZHTTPConnectionCallBackDefaultFailHandler) -> Bool{
        if !self.isNetworkReachable() {
            GZDebugLog("[connection error] there's no network reachable")
            
            var error = NSError(domain: "Network", code: 0, userInfo: ["reason":"no network reachable"])
            
            failHandler(response:  nil, error: error)
            return false
        }
        
        return true
    }
}

//MARK: - NSURLSessionDelegate
extension GZHTTPConnection:NSURLSessionDelegate {
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        GZDebugLog("URLSessionDidFinishEventsForBackgroundURLSession")
        
        var completionHandler = self.backgroundSessionCompletionHandler
        self.backgroundSessionCompletionHandler = nil
        
        completionHandler()
        
        
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
        
    }
}

//MARK: - NSURLSessionTaskDelegate
extension GZHTTPConnection:NSURLSessionTaskDelegate {
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
    }
    
    
}

//MARK: - Convertor
extension GZHTTPConnection {
    
    func convertToTypeImage(data:NSData!) -> (AnyObject!,NSError!){
        
        var image = UIImage(data: data)
        
        return (image, nil)
    }
    
    
    func convertToJSON(data:NSData!) -> (AnyObject!,NSError!){
        
        var jsonError:NSError?
        var jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves, error: &jsonError)
        
        if jsonError != nil {
            
            GZDebugLog("jsonText:\(NSString(data: data, encoding: NSUTF8StringEncoding))")
            
            GZDebugLog("[json error] there are some error happened with serialize json. below is the error message:<\(jsonError?.localizedDescription)>")
            
            var userInfo:[NSObject:AnyObject]! = jsonError?.userInfo
            
            if userInfo != nil {
                userInfo[NSRecoveryAttempterErrorKey] = data
            }
            
            var error = NSError(domain: jsonError!.domain, code: jsonError!.code, userInfo: userInfo)
            
//            self.sendMintHandledDataWithErrorMessage
            
//            self.sendMintHandledDataWithErrorMessage("[json error] there are some error happened with serialize json. below is the error message:<\(jsonError?.localizedDescription)>", error: error)
            
            return (nil, error)
            
        }
        
        return (jsonObject, nil)
        
    }
    
}


//MARK: - Handle Connection Result
private extension GZHTTPConnection {
    
    func handleResult(callbackHandler:__GZHTTPConnectionCallBackDefaultCompletionHandler, url:NSURL!, obj: AnyObject!, response: NSURLResponse!, error: NSError!){
        
        callbackHandler(obj: obj, response: response, error: error)
        
    }
    
    func handleError(callbackHandler:__GZHTTPConnectionCallBackDefaultFailHandler, url:NSURL!, connectionData:GZHTTPConnectionData, response: NSURLResponse!, error: NSError!){
        
        callbackHandler(response: response, error: error)

    }
    
}


// MARK: - GZHTTPConnectionData

class GZHTTPConnectionData:NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate{
    
    var sessionConfiguration:NSURLSessionConfiguration?
    
    var sessionDataTask:NSURLSessionTask?{
        get{
            return self.privateCache.sessionTask
        }
    }
    
    var sessionDelegateQueue:NSOperationQueue?
    
//    var becomeSessionDelegate:Bool = false

    var paramsArray:[GZHTTPConnectionValueParam] = []
    
    var finalParams:[GZHTTPConnectionValueParam] {
        return self.privateCache.finalParamsArrayForConnection
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
    
    private var privateCache = PrivateCache()
    
    func prepare(){
        
    }
    
    func willConvertToSenderData(){
        
    }
    
    func recusiveDependedConnectorDatas(){
        
        self.recusiveDependedConnectorDatas(self.dependedConnectorDatas)
        
        
        self.willConvertToSenderData()
        if self.removeDuplicatedKeysInDependedDatas {
            for param in self.paramsArray {
                self.removeFinalParam(param)
            }
        }

        self.privateCache.finalParamsArrayForConnection += self.paramsArray
        
    }
    
    func recusiveDependedConnectorDatas(connectorDatas:[GZHTTPConnectionData]){

        for connectorData in connectorDatas {
            connectorData.willConvertToSenderData()
            self.privateCache.finalParamsArrayForConnection += connectorData.paramsArray
            self.recusiveDependedConnectorDatas(connectorData.dependedConnectorDatas)
        }
        
    }
    
    func getKeyValueString()->String{
        
        var resultString = ""
        
        var stringConnector = ""
        
        for param in self.finalParams {
            
            var keyValueString = "\(param.key)=\(param.value)"
            resultString += "\(stringConnector)\(keyValueString)"
            
            stringConnector = "&"
        }
        
        return resultString
    }
    
    func getKeyValueData()->NSData{
        
        var resultData:NSMutableData = NSMutableData()
        
        var stringConnector = ""
        
        for param in self.finalParams {
            
            var keyValueString = "\(param.key)=\(param.value)"
            
            resultData.appendData("\(stringConnector)\(keyValueString)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
            
            resultData.appendData("&".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
        }

        return resultData as NSData
    }
    
    func getJSONObject()->[NSObject:AnyObject] {
        var JSONObject:[NSObject:AnyObject] = [:]
        
        for param in self.finalParams {
            JSONObject[param.key] = param.value
        }

        return JSONObject
        
    }
    
    
    
    func getFileUploadData()->NSData{
        
        var data = NSMutableData()
        
        var fileBoundary = ""
        switch self.inputValueType {
        case let .FileUpload(boundary):
            fileBoundary = boundary
        default:
            fileBoundary = "-----\(NSDate().timeIntervalSince1970)"
        }
        
        for param in self.finalParams {
            data.appendData("--\(fileBoundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
            
            switch param.type {
                
            case .String:
                
                GZDebugLog("getFileUploadData key:\(param.key), value:\(param.value)")
                
                data.appendData("Content-Disposition: form-data; name=\"\(param.key)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) ?? NSData())
                data.appendData("\(param.value)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
                
            case .File:
                var fileparam = param as GZHTTPConnectionFileValueParam
                
                data.appendData("Content-Disposition: form-data; name=\"\(param.key)\"; filename=\"\(fileparam.filenmae)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
                data.appendData("Content-Type: \(fileparam.contentType.rawValue)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
                data.appendData(fileparam.value as NSData)
                data.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
                
                
            }

        }
        
        data.appendData("--\(fileBoundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
        
        return data
    }
    
    func senderString() -> String {
        
        var resultString = self.getKeyValueString()
        
        return resultString
    }
    
    
    func senderData() -> NSData {
        
        var data:NSData?
        var jsonError:NSError?
        
        switch(self.inputValueType){
        case .JSON:
            data = NSJSONSerialization.dataWithJSONObject(self.getJSONObject(), options: NSJSONWritingOptions.PrettyPrinted, error: &jsonError)
            
        case .KeyValue:
            data = self.getKeyValueData()//self.senderString().dataUsingEncoding(NSUTF8StringEncoding)
        case .FileUpload:
            data = self.getFileUploadData()
        }
        
        return data!
        
    }
    
    
    
    
}

extension GZHTTPConnectionData {
    
    private struct PrivateCache {
        var session:NSURLSession! = nil
        var sessionTask:NSURLSessionTask! = nil
        var finalParamsArrayForConnection:[GZHTTPConnectionValueParam] = []
        
    }
    
    
    
}

//MARK: - remove Final param
extension GZHTTPConnectionData {
    
    private func removeFinalParam(forKey key:String){
        self.privateCache.finalParamsArrayForConnection = self.finalParams.filter{ return $0.key != key }
    }
    
    private func removeFinalParam(param:GZHTTPConnectionValueParam){
        self.removeFinalParam(forKey: param.key)
    }
    
}


