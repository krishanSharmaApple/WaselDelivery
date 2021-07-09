//
//  ApiManager.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 14/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift
import Log
import BugfenderSDK

class ApiManager {
    
    static let shared = ApiManager()
    
    var apiService: WaselDeliveryService = APIDataService()
    var apiServiceType: APIServiceType = .apiService {
        didSet {
            switch apiServiceType {
            case .staticService:
                apiService = StaticDataService()
            default :
                apiService = APIDataService()
            }
        }
    }

    fileprivate init() { }
    
    fileprivate class func getResponseErrorWithStatusCode(_ statusCode: Int?) -> ResponseError {
        
        if let statusCode_ = statusCode {
            switch statusCode_ {
            case ResponseStatusCode.notFound.rawValue:
                return ResponseError.notFoundError
            case ResponseStatusCode.badRequest.rawValue:
                return ResponseError.badRequestError
            case ResponseStatusCode.timeout.rawValue:
                return ResponseError.timeoutError
            case ResponseStatusCode.internalServer.rawValue:
                return ResponseError.internalServerError
            case ResponseStatusCode.accessTokenExpire.rawValue:
                return ResponseError.accessTokenExpireError
            default:
                return ResponseError.unkonownError
            }
        }
        return ResponseError.unkonownError
        
    }
    
    class func dataTask(_ request: NSMutableURLRequest, params: AnyObject? = nil, shouldUploadImage: Bool? = nil) -> Observable<AnyObject> {
        
        return Observable.create { observer in
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            
            var dataTask: URLSessionDataTask!
            // creating inline function to reuse the API call when accesstoken expired
            func reusable() {
                dataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
                    let response = response as? HTTPURLResponse
                    
                    if let response_ = response, (response_.statusCode == ResponseStatusCode.success.rawValue || response_.statusCode == ResponseStatusCode.orderFail.rawValue || response_.statusCode == ResponseStatusCode.accessTokenExpire.rawValue) {
                        
                        if response_.statusCode != ResponseStatusCode.accessTokenExpire.rawValue {
                            if let data_ = data, data_.count != 0 {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: data_, options: .mutableContainers)
                                    Utilities.log(json as AnyObject, type: .info)
                                    if let json_ = json as? [String: AnyObject], json_.keys.count == 1, nil != json_["message"] as? String {
                                        //                                    BFLog("%@", true as CVarArg, tag: "Response", level: .default)
                                        observer.on(.next(true as AnyObject))
                                    } else {
                                        //                                    if let dict_ = json as? [String: AnyObject] {
                                        //                                        BFLog("%@", dict_ as CVarArg, tag: "Response", level: .default)
                                        //                                    } else if let arr_ = json as? [[String: AnyObject]] {
                                        //                                        BFLog("%@", arr_ as CVarArg, tag: "Response", level: .default)
                                        //                                    } else if let json_ = json as? CVarArg {
                                        //                                        BFLog("%@", json_, tag: "Response", level: .default)
                                        //                                    }
                                        observer.on(.next(json as AnyObject))
                                    }
                                } catch {
                                    observer.on(.error(ResponseError.parseError))
                                }
                            } else {
                                observer.on(.next(true as AnyObject))
                            }
                        } else if response_.statusCode == ResponseStatusCode.accessTokenExpire.rawValue {
                            // To regenerate access token
                            _ =     ApiManager.shared.apiService.refreshAccessToken(["refreshToken": Utilities.getRefreshToken() as AnyObject]).subscribe(
                                onNext: { _ in
                                    // Adding security to previous api after regenearting the access token
                                    generateMD5Encryption(params: params, request: request)
                                    reusable()
                            }, onError: { error in
                                observer.on(.error(ResponseError.accessTokenExpireError))
                            })
                        }
                    } else {
                        if let data_ = data {
                            //                        BFLog("%@", data_ as CVarArg, tag: "Error", level: .error)
                            do {
                                let json = try JSONSerialization.jsonObject(with: data_, options: .mutableContainers) as? [String: Any]
                                if let message = json?["message"] as? String {
                                    observer.on(.error(ResponseError.errorWithMessage(message)))
                                }
                            } catch {
                                observer.on(.error(ResponseError.unkonownError))
                            }
                        } else if let error_ = error {
                            //                        BFLog("%@", error_ as CVarArg, tag: "Error", level: .error)
                            Utilities.log(error_ as AnyObject, type: .error)
                            observer.on(.error(error_))
                        } else {
                            observer.on(.error(ResponseError.unkonownError))
                        }
                    }
                }
                dataTask.resume()
            }
            reusable()
            return Disposables.create {
                // dataTask.cancel()
            }
            }.observeOn(MainScheduler.instance)
    }
    
    class func post(_ path: String, params: AnyObject? = nil, shouldUploadImage: Bool? = nil) -> Observable<AnyObject> {
        return ApiManager.dataTask(clientURLRequest(path, params: params, method: .post, shouldUploadImage: shouldUploadImage), params: params as AnyObject?)
    }

    class func put(_ path: String, params: [String: AnyObject]? = nil) -> Observable<AnyObject> {
        return ApiManager.dataTask(clientURLRequest(path, params: params as AnyObject?, method: .put), params: params as AnyObject?)
    }
    
    class func get(_ path: String, params: [String: AnyObject]? = nil)  -> Observable<AnyObject> {
        return ApiManager.dataTask(clientURLRequest(path, params: params as AnyObject?, method: .get), params: params as AnyObject?)
    }
    
    class func clientURLRequest(_ path: String, params: AnyObject? = nil, method: NetworkMethod, shouldUploadImage: Bool? = nil) -> NSMutableURLRequest {
        
        let baseURLString = "\(baseAPIURL)\(path)"
        let requestUrl = URL(string: baseURLString)
        let request = NSMutableURLRequest(url: requestUrl ?? URL(fileURLWithPath: ""))
        request.httpMethod = method.rawValue
        if let _params = params {
            switch method {
            case .post, .put:
                if let shouldUploadImage_ = shouldUploadImage, shouldUploadImage_ == true, let _params_ = _params as? [String: AnyObject] {
                        request.httpBody = self.shared.generateImageUploadData(params: _params_, forRequest: request)
                    } else {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: _params, options: JSONSerialization.WritingOptions.prettyPrinted)
                            request.httpBody = jsonData
                        } catch let error as NSError {
                            Utilities.log(error, type: .error)
                        }
                    }
            case .get:
                if let _params_ = _params as? [String: AnyObject] {
                    request.url =  formURL(baseURLString, paramDict: _params_) ?? nil
                }
            }
        }
        
        // add headers
        if shouldUploadImage == nil {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if false == shouldUploadImage || nil == shouldUploadImage {
            generateMD5Encryption(params: params, request: request, path: path)
        } else {
            if path.contains("security"), let accessToken_ = Utilities.getAccessToken(), accessToken_.length > 0 {
                request.addValue("Bearer \(accessToken_)", forHTTPHeaderField: "Authorization")
            }
        }

        let _: [String: AnyObject] = ["url": String(describing: request.url) as AnyObject,
                                                "headers": String(describing: request.allHTTPHeaderFields) as AnyObject,
                                                "params": params as AnyObject,
                                                "body": String(describing: request.httpBody) as AnyObject,
                                                "method": String(describing: request.httpMethod) as AnyObject]
        return request
    }
    
    class  func generateMD5Encryption(params: AnyObject? = nil, request: NSMutableURLRequest, path: String = "security") {
        // Generating MD5 encryprion
        let nonce = String.random()
        request.setValue(nonce, forHTTPHeaderField: "nonce")
        
        var paramString = ""
        
        if let params_ = params {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: params_, options: .prettyPrinted)
                if let jsonStr = String(data: jsonData, encoding: .utf8) {
                    paramString = jsonStr
                }
            } catch {
                
            }
        }
        
        var signatureStr = ""
        
        if path.contains("security"), let accessToken_ = Utilities.getAccessToken(), accessToken_.length > 0 {
            
            request.setValue("Bearer \(accessToken_)", forHTTPHeaderField: "Authorization")
            signatureStr = "Bearer \(accessToken_)\(publicKey)\(nonce)\(paramString)"
        } else {
            signatureStr = "\(publicKey)\(nonce)\(paramString)"
        }
        
        let md5Data = signatureStr.MD5()
        let md5Hex =  md5Data.map { String(format: "%02hhx", $0) }.joined()
        request.setValue(md5Hex, forHTTPHeaderField: "signature")
        
    }
    
    fileprivate class func formURL(_ base: String, paramDict: [String: AnyObject]) -> URL? {
        
        var urlComponents = URLComponents(string: base) ?? URLComponents()
        var queryItems = [URLQueryItem]()
        for (key, value) in paramDict {
            queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
        }
        urlComponents.queryItems = queryItems as [URLQueryItem]?
        return urlComponents.url
    }
    
    fileprivate func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    fileprivate func generateImageUploadData(params: [String: AnyObject], forRequest request: NSMutableURLRequest ) -> Data {
        
        let boundary = self.generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        let image_data = params["imageData"] as? Data
        for (key, value) in params where key != "imageData" {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8) ?? Data())
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8) ?? Data())
            body.append("\(value)\r\n".data(using: String.Encoding.utf8) ?? Data())
        }
        
        let fname = "test.jpg"
        let mimetype = "image/jpg"
        body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8) ?? Data())
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8) ?? Data())
        body.append(image_data ?? Data())
        body.append("\r\n".data(using: String.Encoding.utf8) ?? Data())
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8) ?? Data())
        return body
    }
}
