//
//  BKBaseViewController.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 08/10/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Upshot/BrandKinesis.h>
#import <Upshot/WindowRemoveType.h>

@interface BKBaseViewController : UIViewController

@property (nonatomic, copy) BrandKinesisActivityDidDismiss  didDismiss;
@property (nonatomic, copy) BrandKinesisActivityDidAppear   didAppear;
@property (nonatomic, copy) BrandKinesisActivityWillAppear  willAppear;


@property (nonatomic, strong) BKActivity *activity;

/*!
 This method is used to pop and remove the controller
 */
- (void)removeController;

/*!
 This method is used to dismiss  and remove the controller
 */
- (void)dismissController;


- (void)updateActivityStatus:(BKActivity *)activity
                     skipped:(BOOL)skipped;

- (void)createEventForType:(BKWindowRemoveType)type;
@end
