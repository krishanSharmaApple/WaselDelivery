//
//  AppleAuthAPIClient.swift
//  WaselDelivery
//
//  Created by Vali on 15/10/2020.
//

import Foundation
import Unbox
import AuthenticationServices
import DAKeychain

@available(iOS 13.0, *)
class AppleAuthAPIClient: NSObject {
    
    static let shared = AppleAuthAPIClient()
    static let keyEmail = "appleEmail"
    static let keyFullName = "appleFullName"
    fileprivate override init() {}
    
    weak var delegate: AppleAuthAPIClientDelegate?
    
    func authenticateIn(_ viewController: UIViewController) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
}

@available(iOS 13.0, *)
extension AppleAuthAPIClient: ASAuthorizationControllerDelegate {
    /// - Tag: did_complete_authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
            // Create an account in your system.
            let userIdentifier = appleIDCredential.user
            var fullName = appleIDCredential.fullName?.givenName
            var email = appleIDCredential.email
            let token = appleIDCredential.identityToken?.base64EncodedString()
            
            if let appleEmail = email {
                DAKeychain.shared[AppleAuthAPIClient.keyEmail] = appleEmail
            } else {
                email = DAKeychain.shared[AppleAuthAPIClient.keyEmail]
            }
            
            if let appleFullName = fullName {
                DAKeychain.shared[AppleAuthAPIClient.keyFullName] = appleFullName
            } else {
                fullName = DAKeychain.shared[AppleAuthAPIClient.keyFullName]
            }
            
            let userObj: UnboxableDictionary = ["name": fullName ?? "",
                                                "email": email ?? "",
                                                "imageUrl": "",
                                                "id": userIdentifier,
                                                "mobile": "",
                                                "token": token ?? "",
                                                "accountType": AccountType.apple]
            print(userObj)
            
            do {
                let user: User = try unbox(dictionary: userObj)
                self.delegate?.appleAuthClient(self, didSignInFor: user)
            } catch {
                Utilities.showToastWithMessage(error.localizedDescription)
            }
            
        default:
            let userInfo: [String: String] = [NSLocalizedDescriptionKey: "Unable to Login"]
            let err = NSError(domain: "0", code: 0, userInfo: userInfo)
            self.delegate?.appleAuthClient(self, didFailedWithError: err)
        }
    }
    
    /// - Tag: did_complete_error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let userInfo: [String: String] = [NSLocalizedDescriptionKey: "Unable to Login"]
        let err = NSError(domain: "0", code: 0, userInfo: userInfo)
        self.delegate?.appleAuthClient(self, didFailedWithError: err)
    }
    
}

@available(iOS 13.0, *)
protocol AppleAuthAPIClientDelegate: class {
    func appleAuthClient(_ client: AppleAuthAPIClient, didSignInFor user: User)
    func appleAuthClient(_ client: AppleAuthAPIClient, didFailedWithError error: Error)
}
