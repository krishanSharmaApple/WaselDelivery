//
//  UPSHOTActivitySetup.swift
//  WaselDelivery
//
//  Created by Purpletalk on 24/05/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit
import Upshot

class UPSHOTActivitySetup: NSObject, BrandKinesisDelegate {

    private var upshotDeviceToken_ = ""
    private var upshotPushInfo_: [AnyHashable: Any]?
    static let shared = UPSHOTActivitySetup()

    fileprivate override init() { }
    
    func initialiseUPSHOT() {
        // Test credentials ApplicationID: "46e9ee6d-718b-40c8-91ba-ea5ccd3aa01f", ApplicationOwnerID: "f1653f73-445f-4445-b927-ddc394da202c"
        let bkinitializeWithOptionsParams: [String: Any] = [
            BKApplicationID: BKConstants.APPLICATION_ID,
            BKApplicationOwnerID: BKConstants.OWNER_ID,
            BKEnableDebugLogs: true,
            BKFetchLocation: true,
            BKExceptionHandler: true
        ]
        BrandKinesis.sharedInstance().initialize(options: bkinitializeWithOptionsParams, delegate: self)
        BKUIPreferences.preferences()?.delegate = UpshotUICustomization()
    }
    
    // Tags creation
    func showUPSHOTActivities(activityTag: String) {
        BKUIPreferences.preferences()?.delegate = UpshotUICustomization()
        BrandKinesis.sharedInstance().delegate = self
        BrandKinesis.sharedInstance().showActivity(with: .any, andTag: activityTag)
    }
    
    // Send device token to upshot
    func sendDeviceTokenToUpshot(deviceToken: String) {
        upshotDeviceToken_ = deviceToken
        let userInfo = BKUserInfo.init()
        let  externalId = BKExternalId.init()
        externalId.apnsID = deviceToken
        userInfo.externalId = externalId
        userInfo.build(completionBlock: nil)
    }

    /*This method is used to send user details to Upshot*/
    func sendUserDetails() {
        let userInfo = BKUserInfo()
        let externalId = BKExternalId()

        userInfo.externalId = externalId
        /*userInfo.email = UserSession.sharedInstance.email
        externalId.appuID = UserSession.sharedInstance.uid
        userInfo.firstName = UserSession.sharedInstance.firstName
        userInfo.lastName = UserSession.sharedInstance.SecondName*/

        var others = userInfo.others ?? [:]
        others["isGuestUser"] = false
        userInfo.others = others

        userInfo.build(completionBlock: nil)
    }
    
    // On push recieve send data to upshot
    func showPushNotification(userInfo: [AnyHashable: Any]) {
        upshotPushInfo_ = userInfo
        BrandKinesis.sharedInstance().handlePushNotification(withParams: userInfo) { (error) in
            debugPrint(error?.localizedDescription ?? "")
        }
    }
    
// MARK: - Upshot delegate methods

    func brandKinesisAuthentication(_ brandKinesis: BrandKinesis, withStatus status: Bool, error: Error?) {
        if status {
            self.sendDeviceTokenToUpshot(deviceToken: upshotDeviceToken_)
            if let upshotPushInfo = upshotPushInfo_ {
                self.showPushNotification(userInfo: upshotPushInfo)
            }
            self.showUPSHOTActivities(activityTag: "Launch")
        }
    }
    
    func brandkinesisActivityWillAppear(_ brandKinesis: BrandKinesis, for activityType: BKActivityType) {
        NSLog("brandkinesisActivityWillAppear:")
    }
    
    func brandKinesisActivityDidAppear(_ brandKinesis: BrandKinesis, for activityType: BKActivityType) {
    }
    
    func brandKinesisActivityDidDismiss(_ brandKinesis: BrandKinesis, for activityType: BKActivityType) {
    }
    
    func brandkinesisErrorLoadingActivity(_ brandkinesis: BrandKinesis, withError error: Error?) {
        NSLog("brandkinesisErrorLoadingActivity:")
    }
    
    func brandKinesisActivity(_ activityType: BKActivityType, performedActionWithParams params: [AnyHashable: Any]) {
        // In app messages
        NSLog("brandKinesisActivity: params:%@", params)
        // Uncomment the below code for upshot deep link featue
        if let deeplink = params["deepLink"] as? String {
            let appdelegate = UIApplication.shared.delegate as? AppDelegate
            appdelegate?.handlingDeepLink(deepLinkString: deeplink)
        }
    }
    
// MARK: - Events
    
    // Create page event for all the screens
    func createPageViewEvent(currentPage: String) {
        BrandKinesis.sharedInstance().createEvent(BKPageViewNative, params: [BKCurrentPage: currentPage], isTimed: true)
    }
    
    // Create custom events
    func createCustomEvent(eventName: String, params: [String: Any]? = nil) {
        BrandKinesis.sharedInstance().createEvent(eventName, params: params, isTimed: false)
    }
    
    // Create custom timed events for view store
    func createCustomTimedEvent(eventName: String, params: [String: Any]? = nil) {
        BrandKinesis.sharedInstance().createEvent(eventName, params: params, isTimed: true)
    }
    
    // Closed custom timed events for view store
    func closeEvent(eventId: String) {
        BrandKinesis.sharedInstance().closeEvent(forID: eventId)
    }
    
}
