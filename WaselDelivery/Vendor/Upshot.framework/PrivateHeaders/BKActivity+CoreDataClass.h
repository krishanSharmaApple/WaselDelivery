//
//  BKActivity+CoreDataClass.h
//  BrandKinesis
//
//  Created by Anand on 20/09/16.
//  Copyright © 2016 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


typedef NS_ENUM(NSInteger, BKActivityStatus){
    
    BKShowActivtyWithTag = 0,
    BKShowActivityWithBoth = 1,
    BKShowActivityWithId = 2,
};

@class BKActivityTags, BKInbox;

NS_ASSUME_NONNULL_BEGIN

@interface BKActivity : NSManagedObject

@end

NS_ASSUME_NONNULL_END


