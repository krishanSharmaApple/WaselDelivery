//
//  USObject.h
//  BrandKinesis
//
//  Created by Anand on 31/01/16.
//  Copyright © 2016 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface USObject : NSObject


- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

- (NSInteger)validateInteger:(id)object;

- (BOOL)validateBool:(id)object;

- (id)checkValueForKey:(id)key isEmptyFromDictionary:(NSDictionary *)dict;

- (id)validateString:(id)object;

@end
