//
//  BKDatabaseManager.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 04/09/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@protocol BKDatabaseManagerDelegate;





@interface BKDatabaseManager : NSObject{


}


/**
 MOC
 */
@property (readonly, strong, nonatomic, nonnull) NSManagedObjectContext *managedObjectContext;

/**
 MOM
 */
@property (readonly, strong, nonatomic, nonnull) NSManagedObjectModel *managedObjectModel;

/**
 PSC
 */
@property (readonly, strong, nonatomic, nonnull) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, assign) BOOL shouldAllowUserDetails;
+( BKDatabaseManager * _Nonnull)sharedDataBaseManager;


- (NSArray *_Nullable)fetchEntityForName:(NSString *_Nonnull)entityName
                      predicate:(NSPredicate * _Nullable)predicate
                      sortOrder:(NSArray<NSSortDescriptor *> * _Nullable)sortOrder;


- (void)saveSurveyJSON:(NSData * _Nonnull)jsonData withSessionId:(NSString *_Nonnull)sessionId;

- (void)deleteManagedObject:(NSManagedObject *_Nonnull)managedObject;

- (void)deleteInboxDataForinboxContent:(NSArray <BKInbox *>*_Nonnull)inboxArray;

- (void)deleteBadgesData;

- (void)deleteUnwantedMessages:(NSArray * _Nonnull)fileNames;

- (void)saveContext;

- (void)deleteRuleData;

- (void)deleteUserDataFor:(NSString *_Nullable)appuid;

- (NSDictionary * _Nullable)fetchBadges;

- (NSArray * _Nullable)fetchActivityTypes;

- (BOOL)isAppuidActive;

- (void)userInfoWith:(NSString *_Nonnull)appuid state:(NSInteger)state;

- (void)updateUserPrivacy:(NSString *_Nonnull)appuid  WithState:(NSInteger)state andenabled:(BOOL)enable;

- (BOOL)userPrivacySynced:(NSString *_Nonnull)serverDate andState:(NSInteger)serverState;

- (id _Nullable)preferences;


@end


@protocol BKDatabaseManagerDelegate <NSObject>



@end
