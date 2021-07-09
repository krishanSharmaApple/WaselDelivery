//
//  HTTPParamBuilder.h
//  Upshot
//
//  Created by Anand on 11/12/17.
//  Copyright © 2017 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTPParamBuilder : NSObject

+ (NSDictionary *)getParams:(id)parameters;

+ (NSDictionary *)getVersionInfo;
@end
