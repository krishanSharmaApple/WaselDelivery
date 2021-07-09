//
//  BKActivity+CoreDataProperties.h
//  
//
//  Created by anand on 12/04/17.
//
//




NS_ASSUME_NONNULL_BEGIN

@interface BKActivity (CoreDataProperties)

+ (NSFetchRequest<BKActivity *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *activityData;
@property (nullable, nonatomic, copy) NSString *activityId;
@property (nullable, nonatomic, copy) NSString *activityName;
@property (nullable, nonatomic, copy) NSNumber *activityRequested;
@property (nullable, nonatomic, copy) NSNumber *activityStatus;
@property (nullable, nonatomic, copy) NSNumber *activityType;
@property (nullable, nonatomic, copy) NSString *campaignId;
@property (nullable, nonatomic, copy) NSString *compoundID;
@property (nullable, nonatomic, copy) NSNumber *considerSkip;
@property (nullable, nonatomic, copy) NSNumber *currentSession;
@property (nullable, nonatomic, copy) NSNumber *repeatCount;
@property (nullable, nonatomic, copy) NSString *ruleId;
@property (nullable, nonatomic, copy) NSString *journeyId;
@property (nullable, nonatomic, copy) NSString *triviaId;
@property (nullable, nonatomic, copy) NSNumber *segmentType;
@property (nullable, nonatomic, copy) NSNumber *skipCount;
@property (nullable, nonatomic, copy) NSString *jeId;
@property (nullable, nonatomic, retain) NSSet<BKActivityTags *> *activityTags;
@property (nullable, nonatomic, retain) BKInbox *inbox;

@end

@interface BKActivity (CoreDataGeneratedAccessors)

- (void)addActivityTagsObject:(BKActivityTags *)value;
- (void)removeActivityTagsObject:(BKActivityTags *)value;
- (void)addActivityTags:(NSSet<BKActivityTags *> *)values;
- (void)removeActivityTags:(NSSet<BKActivityTags *> *)values;

@end

NS_ASSUME_NONNULL_END
