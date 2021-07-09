//
//  BKInboxInfo.h
//  BrandKinesis
//
//Created by [x]cube LABS on 18/09/14.
//Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Upshot/BKInbox+CoreDataClass.h>
#import "USObject.h"

@protocol BKInboxInfoDelegate;

/*!
 Info completion block is called once the data is inserted.
 This contain all the inbox values.
 shouldShowLoad is flagged according to number of inbox values received from the server if the payload is empty then we consider it as shouldShowLoad = NO
 FetchRequest with no predicate this fetch request can be used for NSFetchedResultsController
 Error is passed when there is a database insertion error
 */
typedef void(^BKInboxInfoCompletion)(NSArray *inboxValues,
                                     BOOL shouldShowLoad,
                                     NSFetchRequest *fetchRequest,
                                     NSError *error);

@interface BKInboxInfo : USObject


@property (nonatomic, weak) id<BKInboxInfoDelegate>delegate;
@property (nonatomic, assign) BOOL rulesLoaded;

/*!
 Fetch the inbox messages from the DataBase
 @param messageId messageId
 @param server bool value to tell wether this is to fetch from server or database since push message does not require fetch from server
 */
- (void)fetchInboxInfo:(BKInboxInfoCompletion)block
         withMessageId:(NSString *)messageId
            fromServer:(BOOL)server;

/*!
 Insert push message give by the developer to the Database 
 ref:inboxInfoInsertedPushPayLoad:withInbox:activityId:error
 */
- (void)insertPushMessageWithParams:(NSDictionary *)params;

/*!
 Fetch the messages from the server
 @param messageId will be a value to fetch from server
 */
- (void)fetchInboxInfoFromServer:(void(^)(id responseObject, NSError *error))block
                   withMessageId:(NSString *)messageId;

/*!
 Update the status of the message to read
 @param messageId id of the selected message
 */
- (void)updateMessageStatusForMessageId:(NSString *)messageId
                         withCompletion:(void(^)(id responseObject, NSError *error))block;

- (BKInbox *)insertDefaultMessageWithParams:(NSDictionary *)params
                                  forappuid:(NSString *)appuid;

- (void)createInboxPayloadWithCompletionBlock:(void(^)(NSArray *inbox))block;

- (BKActivity *)getActivityForId:(NSString *)activityId;

- (void)udpateInboxBadgeStatus:(void(^)(BOOL completion))block;


@end


@protocol BKInboxInfoDelegate <NSObject>

@optional

/*!
 This delegate is called when a push notification is received. Once the message is successfully inserted then this will be the call back
 @param inboxInfo SELF
 @param inbox model this will be ManagedObjectContext Entity
 @param activityId inserted ActivityId
 @param error is occurred where there is an insertion error
 */
- (void)inboxInfoInsertedPushPayLoad:(BKInboxInfo *)inboxInfo
                           withInbox:(BKInbox *)inbox
                          activityId:(NSString *)activityId
                             error:(NSError *)error;


- (void)brandKinesisActivityReadytoShowFor:(BKActivity *)activity;

- (void)inboxActivityInsertionProcessCompleted;

- (void)inboxInfoRulesLoaded;


@end
