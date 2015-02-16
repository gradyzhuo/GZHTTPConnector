//
//  GZHTTPConnection.swift
//  Flingy
//
//  Created by Grady Zhuo on 2014/9/15.
//  Copyright (c) 2014年 Grady Zhuo. All rights reserved.
//

import Foundation


typealias GZHTTPConnectionCompleteHandlerCallBackArray = (array:[AnyObject]!, response:NSURLResponse!, error:NSError!) -> Void

typealias GZHTTPConnectionCompleteHandlerCallBackDictionary = (dictionary:[NSObject:AnyObject]!, response:NSURLResponse!, error:NSError!) -> Void

typealias GZHTTPConnectionCompleteHandlerCallBackObject = (obj:AnyObject!, response:NSURLResponse!, error:NSError!) -> Void

typealias GZHTTPConnectionCompleteHandlerCallBackBoolean = (success:Bool, response:NSURLResponse!, error:NSError!) -> Void


// MARK : CompleteHandler for client-server connection

typealias __GZHTTPConnectionCallBackDefaultCompleteHandler = (obj:AnyObject!, response:NSURLResponse!, error:NSError!) -> Void
typealias __GZHTTPConnectionCallBackDefaultFailHandler = (response:NSURLResponse!, error:NSError!) -> Void


typealias GZHTTPConnectionCallBackDefaultCompleteHandler = (obj:AnyObject!, response:NSURLResponse!, error:NSError!) -> Void
typealias GZHTTPConnectionCallBackDefaultFailHandler = (obj:AnyObject!, response:NSURLResponse!, error:NSError!) -> Void


class GZHTTPConnection:NSObject {
    
    let reachability:Reachability = Reachability.reachabilityForInternetConnection()
    var hostURL:NSURL = NSURL()
    
    var delegateQueue:NSOperationQueue = NSOperationQueue.mainQueue()
    
    lazy var session:NSURLSession = {
        
        var sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.allowsCellularAccess = true
        
        var customSession:NSURLSession = NSURLSession(configuration:sessionConfig , delegate: self, delegateQueue: self.delegateQueue)
        
        return customSession
    }()
    
    lazy var backgroundSession:NSURLSession = {
        var configuration = NSURLSessionConfiguration.backgroundSessionConfiguration("GradyZhuo.GZHTTPConnection.BackgroundMode")
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: self.delegateQueue)
    }()
    
    
    override convenience init() {
        self.init(hostURL:NSURL())
    }
    
    init(hostURL:NSURL){
        super.init()
        
        self.hostURL = hostURL
        self.reachability.startNotifier()
        
//        self.configMintInstance()
        
    }
    
    // MARK: singleton
    class var defaultConnector : GZHTTPConnection! {
        
        dispatch_once(&Cache.once_token){
            Cache.sharedInstance = GZHTTPConnection(hostURL: APPCONFIG_API_BASE_URL)
        }
        
        return Cache.sharedInstance!
    }
    
    private struct Cache {
        static var sharedInstance : GZHTTPConnection?
        static var once_token : dispatch_once_t = 0
    }
    
    func startConnecting(){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func stopConnecting(){
        
        self.session.getTasksWithCompletionHandler { (dataTasks:[AnyObject]!, downloadTasks:[AnyObject]!, uploadTasks:[AnyObject]!) -> Void in
            
            if (dataTasks.count + downloadTasks.count + uploadTasks.count) == 0 {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            
            
        }

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
    
    func defaultConnectionByDefaultHostURL(api:String, connectorData:GZHTTPConnectionData, completionHandler:__GZHTTPConnectionCallBackDefaultCompleteHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)-> NSURLSessionTask?{
        
        var APIURL = self.hostURL.URLByAppendingPathComponent(api)
        
        return self.defaultConnection(url: APIURL, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
        
    }
    
    func defaultConnection(baseURL:NSURL, api:String, connectorData:GZHTTPConnectionData, completionHandler:__GZHTTPConnectionCallBackDefaultCompleteHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)-> NSURLSessionTask?{
        
        var APIURL = baseURL.URLByAppendingPathComponent(api)
        
        return self.defaultConnection(url: APIURL, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
        
    }
    
    
    func defaultConnection(#url:NSURL, connectorData:GZHTTPConnectionData, completionHandler:__GZHTTPConnectionCallBackDefaultCompleteHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)-> NSURLSessionTask?{
        
        var request = NSMutableURLRequest(URL: url)
        
        connectorData.prepare()
        connectorData.recusiveSenderData()
        
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

        
        
        
        
        
        
        
//        if connectorData.inputValueType == GZHTTPConnectionInputValueType.FileUpload {
//            
//            var uploadData = connectorData.senderData()
//            request.setValue("\(uploadData.length)", forHTTPHeaderField: "Content-Length")
//            
//            var charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
//            var contentType = "multipart/form-data; charset=\(charset); boundary=\(connectorData.boundary)"
//            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
//            
//            return self.defaultUploadConnection(request: request, connectorData: connectorData, fromData:uploadData, completionHandler: completionHandler, failHandler: failHandler)
//            
//        }else{
//            
//            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//            return self.defaultConnection(request: request, connectorData: connectorData, completionHandler: completionHandler, failHandler: failHandler)
//        }
        
        
    }
    
    func defaultConnection(#request:NSURLRequest, connectorData:GZHTTPConnectionData , completionHandler:__GZHTTPConnectionCallBackDefaultCompleteHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler) -> NSURLSessionTask? {
        
        if !self.checkISNetworkReachable(failHandler){
            return nil
        }
        
        
        self.startConnecting()
        
        var session = self.session
        
        if connectorData.becomeSessionDelegate {
            
            connectorData.sessionConfiguration = connectorData.sessionConfiguration ?? NSURLSessionConfiguration.defaultSessionConfiguration()
            
            connectorData.sessionDelegateQueue = connectorData.sessionDelegateQueue ?? NSOperationQueue.mainQueue()
            
            session = NSURLSession(configuration: connectorData.sessionConfiguration, delegate: connectorData, delegateQueue: connectorData.sessionDelegateQueue)
            
            connectorData.privateCache.session = session
            
        }
        
        var task:NSURLSessionTask? = session.dataTaskWithRequest(request, completionHandler: { (data:NSData!, response:NSURLResponse!, error:NSError!) -> Void in
            self.connectionCompletionHandler(connectorData, url:request.URL, data: data, response: response, connectionError: error, completionHandler: completionHandler, failHandler: failHandler)
        })
        
        connectorData.sessionTask = task
        
        return task
    }
    
    
    func defaultUploadConnection(#request:NSURLRequest, connectorData:GZHTTPConnectionData, fromData uploadData:NSData!, completionHandler:__GZHTTPConnectionCallBackDefaultCompleteHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler)->NSURLSessionTask?{
        
        if !self.checkISNetworkReachable(failHandler){
            return nil
        }
        
        self.startConnecting()
        
        var session = self.session
        
        if connectorData.becomeSessionDelegate {
            
            connectorData.sessionConfiguration = connectorData.sessionConfiguration ?? NSURLSessionConfiguration.defaultSessionConfiguration()
            
            connectorData.sessionDelegateQueue = connectorData.sessionDelegateQueue ?? NSOperationQueue.mainQueue()
            
            session = NSURLSession(configuration: connectorData.sessionConfiguration, delegate: connectorData, delegateQueue: connectorData.sessionDelegateQueue)
            
            connectorData.privateCache.session = session
            
        }
        
        var task = session.uploadTaskWithRequest(request, fromData:uploadData, completionHandler: { (data:NSData!, response:NSURLResponse!, error:NSError!) -> Void in
            self.connectionCompletionHandler(connectorData, url:request.URL ,data: data, response: response, connectionError: error, completionHandler: completionHandler, failHandler: failHandler)
        })
        
        connectorData.sessionTask = task
        
        return task
        
    }
    
    
    func connectionCompletionHandler(connectorData:GZHTTPConnectionData!, url:NSURL!, data:NSData!, response:NSURLResponse!, connectionError:NSError!, completionHandler:__GZHTTPConnectionCallBackDefaultCompleteHandler, failHandler:__GZHTTPConnectionCallBackDefaultFailHandler) -> Void{
        
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

extension NSURL{
    
    func parametersDictionary() -> [String:String]{
        
        var md:[String:String] = [String:String]()
        var components:NSURLComponents! = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)
        
        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("8.0"){
            
            for obj in components.queryItems! {
                
                var query = obj as NSURLQueryItem
                
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

//MARK: - Handle Connection Result

extension GZHTTPConnection {
    
    func handleResult(callbackHandler:__GZHTTPConnectionCallBackDefaultCompleteHandler, url:NSURL!, obj: AnyObject!, response: NSURLResponse!, error: NSError!){
        
        callbackHandler(obj: obj, response: response, error: error)
        
    }
    
    func handleError(callbackHandler:__GZHTTPConnectionCallBackDefaultFailHandler, url:NSURL!, connectionData:GZHTTPConnectionData, response: NSURLResponse!, error: NSError!){
        
        callbackHandler(response: response, error: error)

    }
    
}


//// MARK: - for Mint
//extension GZHTTPConnection {
//    
//    func configMintInstance(){
////        self.mintInstance.initAndStartSession(GZKIT_MINT_API_KEY)
//    }
//    
//    func sendMintHandledData(#reason:String, connectionData:GZHTTPConnectionData!, response:NSURLResponse!, error:NSError!, completionBlock:((result:MintLogResult!) -> Void)!){
//        
//        if connectionData != nil {
//
////            var senderData = connectionData.senderData()
//            
//            var extraDataList = Mint.sharedInstance().extraDataList
//            
//            if response != nil {
//                extraDataList.add(ExtraData(key: "URL", andValue: "\(response.URL)"))
//            }
//            
//            for param in connectionData.finalParamsArrayForConnection {
//                switch param.type {
//                case .String :
//                    extraDataList.add(ExtraData(key: param.key, andValue: param.value as String))
//                case .File:
//                    var data = param.value as NSData
//                    extraDataList.add(ExtraData(key: param.key, andValue: data.description ))
//                }
//            }
//            
//
//            var exception = NSException(name: "GZKitException", reason: reason, userInfo: error.userInfo)
//            self.sendMintHandledData(limitedExtraDataList:extraDataList, exception: exception, completionBlock: completionBlock)
//        }
//        
//
//    }
//    
//    func sendMintHandledData(#limitedExtraDataList:LimitedExtraDataList!, exception:NSException, completionBlock:((result:MintLogResult!) -> Void)!){
//
//        Mint.sharedInstance().logExceptionAsync(exception, limitedExtraDataList: limitedExtraDataList, completionBlock: completionBlock)
//    }
//    
//
//    func sendMintHandledDataWithErrorMessage(message:String!, error:NSError){
//        var exception = NSException(name: "GZKitException", reason: message, userInfo: error.userInfo)
//        
//        Mint.sharedInstance().logExceptionAsync(exception, limitedExtraDataList: nil, completionBlock: nil)
//    }
//    
//    func sendMintHandledDataWithErrorData(data:NSData!, error:NSError){
//        
//        var limitedExtraData = LimitedExtraDataList()
//        
//
//        
//    }
//}


//MARK: - GZHTTPConnectionData Enums

enum GZHTTPConnectionDataMethod:String{
    case POST = "POST"
    case GET = "GET"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum GZHTTPConnectionInputValueType{
    case JSON, KeyValue
    case FileUpload(String)//Boundary
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
}

class GZHTTPConnectionValueParam{
    var type:GZHTTPConnectionParamType{
        return .String
    }
    var key:String
    var value:AnyObject
    
    init(key:String, value:AnyObject){
        
        self.key = key
        self.value = value
        
    }
    
}


class GZHTTPConnectionStringValueParam: GZHTTPConnectionValueParam {
    //Empty
    
    init(key:String, stringValue:String){
        
        super.init(key: key, value: stringValue)
        
    }
    
}

class GZHTTPConnectionArrayPartValueParam: GZHTTPConnectionValueParam {
    //Empty
    
    init(key:String, arrayValue:[AnyObject]){
        super.init(key: key, value: arrayValue)
    }
    
}

class GZHTTPConnectionFileValueParam: GZHTTPConnectionValueParam {
    
    override var type:GZHTTPConnectionParamType{
        return .File
    }
    
    var filenmae = "Default"
    var contentType:GZHTTPConnectionFileContentType = .All
    
    init(key: String, fileData: NSData) {
        super.init(key: key, value: fileData)
        
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

// MARK: - GZHTTPConnectionData

class GZHTTPConnectionData:NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate{
    
    var sessionConfiguration:NSURLSessionConfiguration?
    var sessionTask:NSURLSessionTask?
    var sessionDelegateQueue:NSOperationQueue?
    var becomeSessionDelegate:Bool = false
    
//    var paramsDict:[String:GZHTTPConnectionValueParam] = [:]
    var paramsArray:[GZHTTPConnectionValueParam] = []
    
    private var finalParamsArrayForConnection:[GZHTTPConnectionValueParam] = []
    
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
    
    var extraHeaderFields:[String:String] = [:]
    
//    var boundary:String = ""
    
    private var privateCache = PrivateCache()
    
    func prepare(){
        
    }
    
    func willConvertToSenderData(){
        
    }
    
    func recusiveSenderData(){
        self.recusiveSenderData(self)
    }
    
    func recusiveSenderData(connectorData:GZHTTPConnectionData){
        
        connectorData.willConvertToSenderData()

        var paramsArray = connectorData.paramsArray
        self.finalParamsArrayForConnection += paramsArray
        
        for depended in connectorData.dependedConnectorDatas {
            self.recusiveSenderData(depended)
        }
        
    }
    
    func getKeyValueString()->String{
        
        var resultString = ""
        
//        var allkeys = self.paramsDict.keys.array
        
        var stringConnector = ""
        
        for param in self.finalParamsArrayForConnection {
            
            var keyValueString = "\(param.key)=\(param.value)"
            resultString += "\(stringConnector)\(keyValueString)"
            
            stringConnector = "&"
        }
        
        return resultString
    }
    
    func getKeyValueData()->NSData{
        
        var resultData:NSMutableData = NSMutableData()
        
        var stringConnector = ""
        
        for param in self.finalParamsArrayForConnection {
            
            var keyValueString = "\(param.key)=\(param.value)"
            
            resultData.appendData("\(stringConnector)\(keyValueString)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
            
            resultData.appendData("&".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData())
        }

        return resultData as NSData
    }
    
    func getJSONObject()->[NSObject:AnyObject] {
        var JSONObject:[NSObject:AnyObject] = [:]
        
        for param in self.finalParamsArrayForConnection {
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
        
        for param in self.finalParamsArrayForConnection {
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
        
        
        
    }
    
}


extension GZHTTPConnectionData {

    func addParam(param:GZHTTPConnectionValueParam){
        self.paramsArray.append(param)
    }
    
    func addParam(key:String, boolValue value:Bool?){
        var defaultValue = false
        
        self.addParam(key, intValue: Int(value ?? defaultValue))
    }
    
    func addParam(key:String, intValue value:Int?){
        var defaultValue = 0
        var stringValue = "\(value ?? defaultValue)"
        self.addParam(key, stringValue: stringValue)
    }
    
    func addParam(key:String, stringValue value:String?){
        var defaultValue = ""
        self.addParam(GZHTTPConnectionStringValueParam(key: key, stringValue: value ?? defaultValue))
    }
    
    func addParam(key:String, stringValueFromArray value:[AnyObject]?, componentsJoinedByString separator:String = ","){
        var defaultValue:[AnyObject] = []
        var stringValue = (value ?? defaultValue).combine(separator)
        self.addParam(key, stringValue: stringValue)
    }
    
    func addParam(contentType:GZHTTPConnectionFileContentType, filename:String, key:String, fileData value:NSData?){
        var defaultValue = NSData()
        self.addParam(GZHTTPConnectionImageDataValueParam(contentType: contentType, filename: filename, key: key, fileData: value ?? defaultValue))
    }
    
    func addAnyFileDataValueParam(filename:String, key:String, fileData value:NSData?){
        self.addParam(.All, filename: filename, key: key, fileData: value)
    }
    
    func addJPEGImageDataValueParam(filename:String, key:String, fileData value:NSData?){
        self.addParam(.JPEG, filename: filename, key: key, fileData: value)
    }
    
    func addJPEGImageDataValueParam(filename:String, key:String, image:UIImage!, compressionQuality:CGFloat){
        
        var data = UIImageJPEGRepresentation(image, compressionQuality)
        self.addJPEGImageDataValueParam(filename, key: key, fileData: data)
        
    }
    
//    func addFileValueParam(key:String, value:){
//        self.addParam(GZHTTPConnectionStringValueParam(key: key, value: value))
//    }
//    

//    func setParams<T>(#key:String, image:UIImage, imageType:GZHTTPConnectionFileContentType){
//
//        var param = GZHTTPConnectionFileValueParam(value: UIImageJPEGRepresentation(image, 0.8))
//        param.contentType = imageType
//        self.setParams(key: key, value: param)
//
//    }

}

//extension GZHTTPConnectionData {
//
//    subscript(key:String)->AnyObject{
//
//
//        get{
//            return self.paramsDict[key]!.value
//        }
//
//        set(value){
//
//            println("key:\(key) value:\(value)")
//            
//            self.setParams(key: key, value: value)
//            
//        }
//        
//    }
//    
//    
//    
//}