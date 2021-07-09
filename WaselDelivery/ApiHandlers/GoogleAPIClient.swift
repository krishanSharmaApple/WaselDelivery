//
//  GoogleAPIClient.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 02/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation
import GoogleSignIn
import Unbox

class GoogleAPIClient: NSObject, GIDSignInDelegate, GIDSignInUIDelegate {
    
    static let shared = GoogleAPIClient()
    fileprivate override init() {}
    
    weak var delegate: GoogleAPIClientDelegate?
    
    func authenticateUsingGoogle() {
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: filePath) as? [String: AnyObject] {
                if let gSignIn = GIDSignIn.sharedInstance() {
                    gSignIn.clientID = dict["CLIENT_ID"] as? String ?? ""
                    gSignIn.delegate = self
                    gSignIn.uiDelegate = self
                    gSignIn.signIn()
                }
            }
        }
    }
    
    class func logout() {
        GIDSignIn.sharedInstance().signOut()
    }
    
    func profilePicUrl() -> String {
        return GIDSignIn.sharedInstance().currentUser.profile.imageURL(withDimension: 30).absoluteString
    }
    
// MARK: - SignIn Delegates -
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {

        if let _delegate = delegate {
            if let user_ = user {
                Utilities.log(user as AnyObject, type: .info)
                let userObj: UnboxableDictionary = ["name": user_.profile.name,
                                                   "email": user_.profile.email,
                                                   "imageUrl": user_.profile.imageURL(withDimension: 100).absoluteString,
                                                   "id": user_.userID,
                                                   "mobile": "",
                                                   "token": user_.authentication.accessToken,
                                                   "accountType": AccountType.google]
                do {
                    let user: User = try unbox(dictionary: userObj)
                    _delegate.googleClient(self, didSignInFor: user, withError: error)
                } catch {
                    Utilities.showToastWithMessage(ResponseError.unboxParseError.description())
                    _delegate.googleClient(self, didSignInFor: nil, withError: error)
                }
            } else if let error_ = error {
                Utilities.showToastWithMessage(error_.localizedDescription)
                _delegate.googleClient(self, didSignInFor: nil, withError: error)
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        if let _delegate = delegate {
            _delegate.googleClient(self, didDisconnectWithError: error)
        }
    }
    
// MARK: - SignIn UI Delegates -
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        if let _delegate = delegate {
            _delegate.googleClient(self, present: viewController)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        if let _delegate = delegate {
            _delegate.googleClient(self, dismiss: viewController)
        }
    }
}

protocol GoogleAPIClientDelegate: class {
    func googleClient(_ client: GoogleAPIClient!, didSignInFor user: User!, withError error: Error!)
    func googleClient(_ client: GoogleAPIClient!, didDisconnectWithError error: Error!)
    func googleClient(_ client: GoogleAPIClient!, present viewController: UIViewController!)
    func googleClient(_ client: GoogleAPIClient!, dismiss viewController: UIViewController!)
}
