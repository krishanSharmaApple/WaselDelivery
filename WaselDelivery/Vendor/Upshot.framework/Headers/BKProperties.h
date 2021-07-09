//
//  ALInterface.h
//  Analytics
//
//  Created by [x]cube LABS on 02/06/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#ifndef BrandKinesis_Interface_h
#define BrandKinesis_Interface_h

#define BK_EXTERN extern

typedef NS_ENUM(NSUInteger, BKEventType){

    /*!
     Session Event
     */
    BKEventSession       = 1,
    /*!
     In app purchase event
     */
    BKEventInAppPurchase = 2,
    /*!
     Heat Map Event
     */
    BKEventHeatMap       = 3,
    /*!
     Location Event
     */
    BKEventLocation      = 4,
    /*!
     Page View Event
     */
    BKEventPageView      = 5,
    
    /*!
     System Event
     */
    BKEventSystem        = 6,
    
    /*!
     Activity Event
     */
    BKEventActivity      = 7,
    /*!
     Custom Event
     */
    BKEventCustom        = 8,

    /*!
     BKAd Events
     */
    BKEventAds           = 9,
    

    
};


typedef NS_ENUM(NSUInteger, BKEventSubType){
    
    /*Custom Event*/
    BKSEventCustom               = 8,

    /*Session*/
    BKEventSessionStarted        = 100,
    BKEventSessionInterrupted    = 101,
    BKEventSessionCompleted      = 102,
    BKEventAttribution           = 104,

    /*Pageview*/
    BKEventPageViewNative        = 112,
    BKEventPageViewWeb           = 113,
    
    /*Syetem Event*/
    BKEventCrash                 = 114,
    BKEventOOM                   = 115, // Event Out Of Memory (OOM)

    /*Activities*/
    BKEventActivityRequested     = 120,
    BKEventActivityTaken         = 121,
    BKEventActivityResponded     = 122,
    BKSEventActivityPushReceived = 123,
    BKEventActivitySkiped        = 124,
    BKEventActivityDONOTSHOW     = 125,
    BKEventAdDisplayed           = 126,
    BKEventAdClicked             = 127,
    BKEventLocalPushReceived     = 128,
    /*HeatMaps*/
    BKEventHeatmapTap            = 130,
    BKEventHeatmapDoubleTap      = 131,
    BKEventHeatmapTripleTap      = 132,
    BKEventHeatmapLongTap        = 133,
    BKEventHeatmapPinch          = 134,
    BKEventHeatmapSwipe          = 135,
    BKEventHeatmapCustomGesture  = 136,
    
    BKEventLocationUser          = 140,
    BKEventLocationthers         = 141,

    /*Banner Ads*/
    BKEventBannerDisplayed       = 137,
    BKEventBannerUnitClicked     = 138,

    BKSEventInAppPurchase        = 139,
        
};


typedef NS_ENUM(NSInteger, BKCloseEventTimeType) {
   
    BKAllEvents,
    BKEventLatest,
    BKEventOldest,

};

//App ID, owner ID, DevID


BK_EXTERN NSString *const BKFetchLocation;
BK_EXTERN NSString *const BKApplicationID;
BK_EXTERN NSString *const BKApplicationOwnerID;
BK_EXTERN NSString *const BKExceptionHandler;
BK_EXTERN NSString *const BKEnableDebugLogs;
BK_EXTERN NSString *const BKUseCellularData;



#endif
