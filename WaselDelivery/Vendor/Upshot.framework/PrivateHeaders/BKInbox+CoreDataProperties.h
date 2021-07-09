//
//  <Upshot/BKInbox+CoreDataProperties.h>
//  
//
//  Created by anand on 12/04/17.
//
//

#import <Upshot/BKInbox+CoreDataClass.h>


NS_ASSUME_NONNULL_BEGIN

@interface BKInbox (CoreDataProperties)

+ (NSFetchRequest<BKInbox *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *appuid;
@property (nullable, nonatomic, retain) NSData *customData;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSDate *formatedDate;
@property (nullable, nonatomic, copy) NSDate *insertedDate;
@property (nullable, nonatomic, copy) NSString *message;
@property (nullable, nonatomic, copy) NSString *messageId;
@property (nullable, nonatomic, copy) NSNumber *status;
@property (nullable, nonatomic, retain) NSSet<BKActivity *> *activity;

@end

@interface BKInbox (CoreDataGeneratedAccessors)

- (void)addActivityObject:(BKActivity *)value;
- (void)removeActivityObject:(BKActivity *)value;
- (void)addActivity:(NSSet<BKActivity *> *)values;
- (void)removeActivity:(NSSet<BKActivity *> *)values;

@end

NS_ASSUME_NONNULL_END
