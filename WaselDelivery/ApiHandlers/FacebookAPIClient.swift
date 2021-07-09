//
//  FacebookAPIClient.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 04/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit
import Unbox

class FacebookAPIClient: NSObject {
    static let shared = FacebookAPIClient()
    fileprivate override init() {}
    
    weak var delegate: FacebookAPIClientDelegate?
    var loginManager = LoginManager()
    
    func authenticateIn(_ viewController: UIViewController) {
        
        loginManager.logOut()
        loginManager.logIn(permissions: ["email", "public_profile"], from: viewController) { (loginResult, error) in
            if let error = error {
                if let delegate_ = self.delegate {
                    delegate_.facebookClient(self, didFailedWithError: error)
                }
            } else if nil != loginResult {
                self.fetchDetails()
            } else {
                let userInfo: [String: String] = [NSLocalizedDescriptionKey: "Unable to Login"]
                let err = NSError(domain: "0", code: 0, userInfo: userInfo)
                if let delegate_ = self.delegate {
                    delegate_.facebookClient(self, didFailedWithError: err)
                }
            }
        }
    }
    
    class func logout() {
        LoginManager().logOut()
    }
    
    fileprivate func fetchDetails() {
        if FBSDKCoreKit.AccessToken.current != nil {
            GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (_, result, error) -> Void in
                if error == nil, let result = result as? [String: Any] {
                    Utilities.log(result as AnyObject, type: .info)
                    let userObj: UnboxableDictionary = ["name": result["name"] ?? "",
                                                        "email": result["email"] ?? "",
                                                        "imageUrl": result["link"] ?? "",
                                                        "id": result["id"] ?? "",
                                                        "mobile": "",
                                                        "token": FBSDKCoreKit.AccessToken.current?.tokenString ?? "",
                                                        "accountType": AccountType.facebook]
                    
                    do {
                        let user: User = try unbox(dictionary: userObj)
                        if let delegate_ = self.delegate {
                            delegate_.facebookClient(self, didSignInFor: user)
                        }
                    } catch {
                        Utilities.showToastWithMessage(error.localizedDescription)
                    }
                } else {
                    let userInfo: [String: String] = [NSLocalizedDescriptionKey: "Unable to fetch user details"]
                    let err = NSError(domain: "0", code: 0, userInfo: userInfo)
                    if let delegate_ = self.delegate {
                        delegate_.facebookClient(self, didFailedWithError: err)
                    }
                }
            })
        } else {
            let userInfo: [String: String] = [NSLocalizedDescriptionKey: "Unable to fetch user details"]
            let err = NSError(domain: "0", code: 0, userInfo: userInfo)
            if let delegate_ = self.delegate {
                delegate_.facebookClient(self, didFailedWithError: err)
            }
        }
    }
}

protocol FacebookAPIClientDelegate: class {
    func facebookClient(_ client: FacebookAPIClient, didSignInFor user: User)
    func facebookClient(_ client: FacebookAPIClient, didFailedWithError error: Error)
}
