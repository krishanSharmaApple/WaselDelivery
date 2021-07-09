//
//  BKUserInfo.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 15/09/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BKUserInfoCompletion)(BOOL success,  NSError * _Nullable error);

/*!
 @brief  This is gender constant
 */
typedef NS_ENUM(NSUInteger, BKGender){
    
    /*!
     @brief  Male
     */
    BKGenderMale        = 1,
    /*!
     @brief  Female
     */
    BKGenderFemale      = 2,
    /*!
     @brief  Others
     */
    BKGenderOther       = 3,
    
    /*!
     @brief  Reset
     */
    BKGenderReset        = 4,

};

/*!
 @brief  User Marital status
 */
typedef NS_ENUM(NSUInteger, BKMaritalStatus){
    
    /*!
     @brief  Single
     */
    BKMaritalStatusSingle        = 1,
    /*!
     @brief  Engaged
     */
    BKMaritalStatusEngaged       = 2,
    /*!
     @brief  Married
     */
    BKMaritalStatusMarried       = 3,
    /*!
     @brief  Widowed
     */
    BKMaritalStatusWidowed       = 4,
    /*!
     @brief  Divorced
     */
    BKMaritalStatusDivorced      = 5,
    /*!
     @brief  Widower
     */
    BKMaritalStatusWidower       = BKMaritalStatusWidowed,
    
    /*!
     @brief  Reset
     */
    BKMaritalStatusReset        =  6,

};


@interface BKDob : NSObject


@property (nonatomic, strong, nullable) NSNumber      * year;
@property (nonatomic, strong, nullable) NSNumber      * month;
@property (nonatomic, strong, nullable) NSNumber      * day;

@end

@interface BKExternalId : NSObject // Should change this to BKExternalID, use

@property (nonatomic, strong, nullable) NSString      * apnsID;
@property (nonatomic, strong, nullable) NSString      * appuID;
@property (nonatomic, strong, nullable) NSString      * facebookID;
@property (nonatomic, strong, nullable) NSString      * twitterID;
@property (nonatomic, strong, nullable) NSString      * foursquareID;
@property (nonatomic, strong, nullable) NSString      * linkedinID;
@property (nonatomic, strong, nullable) NSString      * googleplusID;
@property (nonatomic, strong, nullable) NSString      * enterpriseUID;
@property (nonatomic, strong, nullable) NSString      * advertisingID;
@property (nonatomic, strong, nullable) NSString      * instagramID;

@property (nonatomic, strong, nullable) NSString      * pinterest;
@property (nonatomic, strong, nullable) NSDictionary  * otherExternalIds;

@end

@interface BKUserInfo : NSObject

@property (nonatomic, strong, nullable) NSString      * lastName;
@property (nonatomic, strong, nullable) NSString      * middleName;
@property (nonatomic, strong, nullable) NSString      * firstName;
@property (nonatomic, strong, nullable) NSString      * language;

@property (nonatomic, strong, nullable) NSString      * occupation;
@property (nonatomic, strong, nullable) NSString      * qualification;
@property (nonatomic, strong, nullable) NSString      * phone;
@property (nonatomic, strong, nullable) NSString      * localeCode;

@property (nonatomic, strong, nullable) NSString      * userName;
@property (nonatomic, assign) BKGender      gender;
@property (nonatomic, assign) BKMaritalStatus maritalStatus;
@property (nonatomic, strong, nullable) NSNumber      * age;
@property (nonatomic, strong, nullable) CLLocation    * location;
@property (nonatomic, strong, nullable) NSString      * email;

@property (nonatomic, strong, nullable) NSNumber      * emailOptout;
@property (nonatomic, strong, nullable) NSNumber      * smsOptout;
@property (nonatomic, strong, nullable) NSNumber      * pushOptout;
@property (nonatomic, strong, nullable) NSNumber      * dataOptout;
@property (nonatomic, strong, nullable) NSNumber      * ipOptout;

@property (nonatomic, strong, nullable) NSNumber      * notificationStatus;

@property (nonatomic, strong, nullable) BKDob         * dateOfBirth;
@property (nonatomic, strong, nullable) BKExternalId  * externalId;// should change this to externalIds
@property (nonatomic, strong, nullable) NSDictionary  * others;
@property (nonatomic, strong, nullable) NSDictionary  * attribution;

/*!
 @brief once the object is created use this method to send the packet to server
 
 @since 1.0
 */
- (void)buildUserInfoWithCompletionBlock:(BKUserInfoCompletion _Nullable )block;


/*!
 @brief  Builds user Info
 
 @deprecated This method is deprecated instead use buildUserInfoWithCompletionBlock:
 
 @since 0.9
 */
- (void)buildUserInfo DEPRECATED_MSG_ATTRIBUTE("use buildUserInfoWithCompletionBlock: instead");

@end


