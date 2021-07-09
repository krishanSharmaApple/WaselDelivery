//
//  BrandKinesis.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 20/08/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//  Upshot Version 1.6.1

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Upshot/BKUserInfo.h>
#import <Upshot/BKProperties.h>
#import <Upshot/BKInterface.h>
#import <Upshot/BKUIPreferences.h>
#import <UIKit/UIKit.h>



typedef NS_ENUM(NSUInteger, BKTutorialViewPlacement) {
    BKTutorialViewPlacementLeft,
    BKTutorialViewPlacementRight,
    BKTutorialViewPlacementTop,
    BKTutorialViewPlacementBottom,
};



typedef NS_ENUM(NSUInteger, BKTutorialTextPlacement) {
    BKTutorialTextPlacementLeft,
    BKTutorialTextPlacementRight,
    BKTutorialTextPlacementTop,
    BKTutorialTextPlacementBottom,
};



typedef void(^_Nullable BrandKinesisActivityWillAppear)(BOOL willAppear, BKActivityType activityType);
typedef void(^_Nullable BrandKinesisActivityDidAppear)(BOOL didAppear, BKActivityType activityType);
typedef void(^_Nullable BrandKinesisActivityDidDismiss)(BOOL didDismiss, BKActivityType activityType);

typedef void(^_Nullable BrandKinesisReferralDetail)( NSDictionary * _Nullable details,  NSError * _Nullable error);

typedef void(^_Nullable BrandKinesisCompletionBlock)(NSError * _Nullable error);
typedef void(^_Nullable BrandKinesisPushCompletionBlock)(BOOL status, NSError * _Nullable error);
typedef void(^_Nullable BrandKinesisFetchCompletion)(id _Nullable responseObject, NSError * _Nullable error );
typedef void(^_Nullable BrandKinesisUserStateCompletion)(BOOL status, NSError * _Nullable error);
typedef void(^_Nullable BrandKinesisRewardsCompletionBlock)(NSDictionary * _Nullable response, NSString * _Nullable errorMessage);

/**
 * Key used to define the current screen name
 * in BKPageView
 */
BK_EXTERN NSString *_Null_unspecified const BKCurrentPage;

/**
 Use this key to create native pageView event
 */
BK_EXTERN NSString *_Null_unspecified const BKPageViewNative;

/**
 Use this key to create web pageView event
 */
BK_EXTERN NSString *_Null_unspecified const BKPageViewWeb;

/**
 * Key used to define ItemID for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemID;
/**
 * Key used to define category for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemCategory;
/**
 * Key used to define sub category for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemSubCategory;
/**
 * Key used to define item price for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemPrice;
/**
 * Key used to define item currency for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemCurrency;
/**
 * Key used to define items purchased for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemQuantity;
/**
 * Key used to define item purchased date for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemsPurchasedDate;
/**
 * Key used to define items purchased total for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemsPurchasedTotal;
/**
 * Key used to define purchased state for BKEventInAppPurchase
 */
BK_EXTERN NSString *_Null_unspecified const BKIAPItemPurchasedState;

//Push API Key's
BK_EXTERN NSString *_Null_unspecified const BKPushUserId;
BK_EXTERN NSString *_Null_unspecified const BKPushAppuid;
BK_EXTERN NSString *_Null_unspecified const BKPushEmailId;
BK_EXTERN NSString *_Null_unspecified const BKPushTitle;
BK_EXTERN NSString *_Null_unspecified const BKPushSubTitle;
BK_EXTERN NSString *_Null_unspecified const BKPushmessage;
BK_EXTERN NSString *_Null_unspecified const BKPushSoundName;
BK_EXTERN NSString *_Null_unspecified const BKPushCategory;
BK_EXTERN NSString *_Null_unspecified const BKPushAttachmentUrl;
BK_EXTERN NSString *_Null_unspecified const BKPushAttachmentType;
BK_EXTERN NSString *_Null_unspecified const BKPushDeeplink;
BK_EXTERN NSString *_Null_unspecified const BKPushBadge;
BK_EXTERN NSString *_Null_unspecified const BKEnhancedPush;
BK_EXTERN NSString *_Null_unspecified const BKPushUserInfo;
BK_EXTERN NSString *_Null_unspecified const BKPushPayload;
BK_EXTERN NSString *_Null_unspecified const BKPushtag;
BK_EXTERN NSString *_Null_unspecified const BKPushValidtill;
BK_EXTERN NSString *_Null_unspecified const BKPushSandbox;
BK_EXTERN NSString *_Null_unspecified const BKPushkey;
BK_EXTERN NSString *_Null_unspecified const BKPushKeyType;
BK_EXTERN NSString *_Null_unspecified const BKPushValueType;
BK_EXTERN NSString *_Null_unspecified const BKPushValueUrl;
BK_EXTERN NSString *_Null_unspecified const BKPushAppId;
BK_EXTERN NSString *_Null_unspecified const BKPushAccountId;

BK_EXTERN NSString *_Null_unspecified const BKAttributionSource;
BK_EXTERN NSString *_Null_unspecified const BKUTM_Source;
BK_EXTERN NSString *_Null_unspecified const BKUTM_Medium;
BK_EXTERN NSString *_Null_unspecified const BKUTM_Campaign;

@interface BrandKinesis : NSObject

@property (nonatomic, strong, nullable) NSDictionary *applicationLaunchOptions;

/*!
 Dispatch Timer, this timer is used to dispatch the packets to server
 By Default 10 seconds
 */
@property (nonatomic, assign) NSTimeInterval dispatchInterval;


/*!
  This will Get the current Location
  Current Location is ignored if set multiple times
 */
@property (nonatomic, strong, nullable) CLLocation *currentLocation;


/*!
 This will be YES if the brand kinesis is authenticated
 */
@property (nonatomic, readonly, getter = isAuthenticated) BOOL isAuthenticated;

/*!
 This will Get Current SDK Version if the brand kinesis is authenticated
 */

@property (nonatomic, readonly, nullable) NSString *version;

/*!
 Brandkinesis Delegate
 */
@property (nonatomic, weak, nullable) id delegate;



/*!
 @brief sharedManager
 
 @since 0.9
 */
+ (nonnull BrandKinesis *)sharedInstance;



-(nonnull instancetype) init __attribute__((unavailable("init not available use sharedInstance")));

/*!
 @brief This will initialize the BrandKinesis and starts a New BrandKinesis session
 
 @code
 NSDictionary *options = 
 @@{BKApplicationID: kAppID,
 BKApplicationOwnerID: kOwnerId, 
 BKFetchLocation: [NSNumber numberWithBool:YES], 
 BKEnableDebugLogs: [NSNumber numberWithBool:YES], 
 BKUseCellularData:[NSNumber numberWithBool:YES],
 BKExceptionHandler:[NSNumber numberWithBool:NO]
 }
 @endcode
 
 @param options Containing initialization paramaters for BrandKiensis {@link BKProperties.h}
 
 @param delegate delegate class  brandKinesisAuthentication:didCompleteWithStatus:
 
 @since 0.9
 */
- (void)initializeWithOptions:(nonnull NSDictionary *)options
                              delegate:(nullable id)delegate;

+ (void)initializeWithOptions:(nonnull NSDictionary *)options
                     delegate:(nullable id)delegate __deprecated_msg("use instance -(void)initializeWithOptions:delegate:");

/**
 This is used for Simple/Auto initialisation where All options will be fetched from JSON file which was downloaded from the Dashboard
 @since 1.3.3
 */
- (void)initializeWithDelegate:(nullable id)delegate;

/*!
 @brief This method is used to create an Event
 
 @param eventType Event Type {@@link BKProperties.h}
 
 @param subEventType subEvent Type {@@link BKProperties.h}
 
 @param params rules when creating data to events This parameter accepts data in key-value pairs.All the keys must be strings. Each value must be a string or a number. Anything other than that, will be converted and stored as string. Maximum Length of params is 2048 bytes. Special characters are not allowed in keys.

 @b Parameter rules when creating data to PageView events @@b
 All rules that apply while creating event apply here also. The hashmap should contain the key BKCurrentPage to make this event a PageView event The default value for the launch screen will be termed as "Home". Pagination and closing this page event will be maintained by BK sdk.
 
 @b Parameter rules when creating data to Social events @@b
 All rules that apply while creating event apply here also. The hashmap should contain the key BKNetworkType and BKNetworkAction to make this event a Social event.
 
 @return eventID UDID string if Event Created successfully, nil if created event is invalid
 
 @note Event types  - BKEventSession , BKEventActivity, BKEventAds should not be used while creating events.
 
 @since 0.9
 */
/*- (nullable NSString *)createEventWithType:(BKEventType)eventType
                         subType:(BKEventSubType)subEventType
                          params:(nullable NSDictionary *)params
                         isTimed:(BOOL)timed;*/

/**
 @since v1.3.3
 */
- (nullable NSString *)createEvent:(nonnull NSString *)name params:(nullable NSDictionary *)params isTimed:(BOOL)timed;


/**
 @brief This location will help in traction the user location, once the location is send to this method it will calculate the position of the user/Device and trigger the rule, if the application is in the background it will pop a local notification and in case of foreground it will pop a Activity based on the rule
 @since v1.4
 */
- (void)createLocationEvent:(CGFloat)latitude longitude:(CGFloat)longitude;

- (nullable NSString *)createAttributionEvent:(nonnull NSDictionary *)payload;

/*!
 @brief Add additional data to the created event
 This method can be called preferably after calling createEventWithType:subType:values:isTimed:
 Adds data if the event still exists and close the event
 
 @param params rules when creating data to events This parameter accepts data in key-value pairs.All the keys must be strings. Each value must be a string or a number.Anything other than that, will be converted and stored as string. Maximum Length param is 2048 bytes. Special characters are not allowed in keys.

 @b Parameter rules when creating data to PageView events
 All rules that apply while creating event apply here also. The hashmap should contain the key BKCURRENTPAGE to make this event a PageView event The default value for the launch screen will be termed as "Home". Pagination and closing this page event will be maintained by BK sdk.
 
 @b Parameter rules when creating data to Social events
 All rules that apply while creating event apply here also. The hashmap should contain the key BKNetworkType and BKNetworkAction to make this event a Social event.
 
 @param eventId EventID
 
 @return YES if events modified successfully for the given eventId
 
 @since 0.9
 */
- (BOOL)setValueAndClose:(nullable NSDictionary *)params forEvent:(nonnull NSString *)eventId;


/**
 @brief  This will close the last create event/ close all the events based on the close type
 @since 1.3.3
 */
- (void)closeEvent:(nonnull NSString *)name ofTimeType:(BKCloseEventTimeType)closeType;


/*!
 @brief  close the event for the given eventId
 
 @param eventId eventId
 
 @since 0.9
 */
- (void)closeEventForID:(nonnull NSString *)eventId;

/*!
 @brief At any instanse BrandKinesis Will dispatch all pending events
 
 @since 1.2.2
 */
- (void)dispatchEventsWithTimedEvents:(BOOL)timedEvents
                      completionBlock:(void(^ _Nullable)(BOOL dispatched))completionBlock;

/*!
  @brief This method will show the activity in a seperate window and once done this window is removed as soon as the activity is completed
 
 @param type activity Type
 @param tag  tag of that particular activity
 
 @since 0.9
 */
- (void)showActivityWithType:(BKActivityType)type
                      andTag:(nullable NSString *)tag;

- (void)removeTutorials;


- (nonnull NSDictionary *)getUserBadges;

- (void)fetchInboxInfoWithCompletionBlock:(void(^ _Nullable)(NSArray * _Nonnull inbox))block;

- (void)showActivityWithActivityId:(nonnull NSString *)activityId;

- (NSDictionary *_Nullable)getUserDetails:(NSArray *_Nullable)keys;

- (void)resetData;

/*!
 @brief Handle push notification data received. 
 This method provides a callback after the given pushPayload has been saved succesfully
 
 @param userinfo userInfo is the push notification payload

 @since 0.9
 */
- (void)handlePushNotificationWithParams:(nonnull NSDictionary *)userinfo
                     withCompletionBlock:(BrandKinesisCompletionBlock)block;



/*!

 @brief Stops the ad for the provided view or stops all ads if no view is provided.
 
 @param view This can be nil, if nil all views in the memory will be removed
 
 @param actvityType YES will remove all banner ads, NO will remove all custom ads
 
*/
- (void)stopAdForView:(nullable UIView *)view
             withType:(BKActivityType)actvityType;




/*!
 @brief BrandKinesis will be terminated

 @since 0.9
 */
- (void)terminate;

/*!
 
 */
- (void)sendPushDetails:(nonnull NSDictionary *)pushDetails withCompletionBlock:(BrandKinesisPushCompletionBlock)block;

- (void)disableUser:(BOOL)shouldDisable completion:(BrandKinesisUserStateCompletion)block;

- (NSString *_Nonnull)getUserId;

- (void)getRewardsStatusWithCompletionBlock:(BrandKinesisRewardsCompletionBlock _Nullable)completionBlock;

- (void)getRewardHistoryForProgramId:(NSString *_Nonnull)programId
                     withHistoryType:(BKRewardHistoryType)historyType
                 withCompletionBlock:(BrandKinesisRewardsCompletionBlock)completionBlock;

- (void)getRewardDetailsForProgramId:(NSString * _Nonnull )programId
                 withCompletionblock:(BrandKinesisRewardsCompletionBlock _Nullable )completionBlock;

- (void)redeemRewardsWithProgramId:(NSString * _Nonnull)programId
                  transactionValue:(NSInteger)transactionAmount
                       redeemAmout:(NSInteger)redeemValue
                               tag:(NSString *_Nonnull)tag
               withCompletionblock:(BrandKinesisRewardsCompletionBlock)completionBlock;

@end


@protocol BrandKinesisDelegate <NSObject>

@optional

- (void)brandKinesisAuthentication:(nonnull BrandKinesis *)brandKinesis withStatus:(BOOL)status
                         error:(nullable NSError *)error;


- (void)brandkinesisErrorLoadingActivity:(nonnull BrandKinesis *)brandkinesis
                               withError:(nullable NSError *)error;

- (void)brandkinesisActivityWillAppear:(nonnull BrandKinesis *)brandKinesis forActivityType:(BKActivityType)activityType;

- (void)brandKinesisActivityDidAppear:(nonnull BrandKinesis *)brandKinesis forActivityType:(BKActivityType)activityType;

- (void)brandKinesisActivityDidDismiss:(nonnull BrandKinesis *)brandKinesis forActivityType:(BKActivityType)activityType;

- (void)brandKinesisUserRating:(NSInteger)rating  withType:(NSInteger)ratingType;

- (void)brandKinesisActivity:(BKActivityType)activityType
   performedActionWithParams:(nonnull NSDictionary *)params;


- (nonnull NSArray *)brandKinesisExludeActivitiesForShare;


/*!
 @brief  Called once when an Ad having impression in a AdUnit
 
 @param adsView view with bouds.widthX50 Height
 
 @since 1.0
 */
- (void)brandKinesisDidReceiveView:(nullable UIView *)adsView
                            forTag:(nullable NSString *)tag;



/*!
 @brief  Notifies that its view is about to be added to a view hierarchy.
 
 @since 1.0
 */
- (void)brandKinesisWillDisplayAd;

/*!
 @brief  Notifies the view controller that was dismissed modally by the receiver.
 
 @since 1.0
 */
- (void)brandKinesisDidDismissAd;

/*!
 @author [x]cube LABS, 15-03-12 16:03:22
 
 @brief  The banner/Interstitial view that failed to load an advertisement
 
 @param error The error object that describes the problem.
 
 @since 1.0
 */
- (void)brandKinesisAdsError:(nullable NSError *)error;


@end
