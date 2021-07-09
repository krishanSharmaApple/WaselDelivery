//
//  BKActivityEvents.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 23/09/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BKActivityEvent : NSObject

- (void)createEventWithSubType:(BKEventSubType)subEventType
                        values:(NSDictionary *)values
                       isTimed:(BOOL)timed;

- (void)setValue:(NSDictionary *)values;

- (void)closeEvent;

@end
