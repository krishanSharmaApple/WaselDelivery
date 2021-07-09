//
//  BKSurveyHandler.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 04/09/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^_Nullable BKResponseCompletionBlock)(id _Nullable responseData, NSError * _Nullable error);

@interface BKActivityHandler : NSObject

@property (nonatomic, copy) BKResponseCompletionBlock completionBlock;

+ (BKActivityHandler * _Nonnull)defaultHandler;

- (void)startDispatching:( void(^ _Nullable )(BOOL completed))completed;

- (void)sendActivity:( NSData * _Nonnull )surveyData
        ForSessionID:( NSString * _Nonnull )sessionId
withCompletionBlock:(BKResponseCompletionBlock)block;

@end
