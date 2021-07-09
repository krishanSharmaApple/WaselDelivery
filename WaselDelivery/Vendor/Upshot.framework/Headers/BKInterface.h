//
//  BKInterface.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 23/08/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#ifndef BrandKinesis_BKInterface_h
#define BrandKinesis_BKInterface_h

#import <UIKit/UIKit.h>

#define BK_EXTERN extern

/*!
 Select the type of activity
 BKActivityTypeAny will give you a random activity
 */
typedef NS_ENUM(NSInteger, BKActivityType) {
    /*!
     @brief  Get Activity of Any time with given tag
     */
    BKActivityTypeAny          = -1,
    /*!
     @brief  Get survey activity
     */
    BKActivityTypeSurvey       = 0,
    /*!
     @brief  Get rating activity
     */
    BKActivityTypeRating       = 1,
    /*!
     @brief  Get Banner Ad
     */
    BKActivityTypeBanner       = 2,
    /*!
     @brief  Get Full screen Ad
     */
    BKActivityTypeFullScreen   = 3,
    /*!
     @brief  Get Custom Ad
     */
    BKActivityTypeCustomAds    = 4,
    /*!
     @brief  Get Opinion poll
     */
    BKActivityTypeOpinionPoll  = 5,

    /*!
     @brief  Get Tutorilas
     */
    BKActivityTypeTutorials    = 7,

    /*!
     @brief In app message
     */
    BKActivityTypeInAppMessage = 8,

    /*!
     @brief Badges
     */
    BKActivityTypeBadges       = 9,

    /*
     @brief ScreenTips
    */
    BKActivityTypeScreenTips   = 10,

    /*
     @brief Triva
     */
    BKActivityTypeTrivia       = 11,
    /*
     @brief WebComponent
     */
    BKActivityTypeWebComponent = 12,
    /*
     @brief MiniGame
     */
    BKActivityTypeMiniGame = 13,
    
   
};


typedef NS_ENUM (NSInteger, BKAdError){
    BKAdErrorUnknown      = -1,
    BKAdErrorInternal     = -2,
    BKAdErrorAdsCompleted = -3,
    BKAdErrorAdsNotFound  = -4
};

typedef NS_ENUM(NSInteger, BKRewardHistoryType) {
    
    BKRewardEntireHistory       = 0,
    BKRewardEarnHistory         = 1,
    BKRewardExpiryHistory       = 2,
    BKRewardRedeemHistory       = 3,
    BKRewardNegativeHistory     = 4
    
};


#endif
