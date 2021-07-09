//
//  BKUtilities.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 25/08/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BKUtilities : NSObject

+ (NSBundle *)getBrandKinesisBundle;

+ (NSDictionary *)getPlatformInfo;

/*!
 This is location Info
 
 @return location PayLoad with City, state, latitude, longitude
 */
+ (id)getLocationInfo;

+ (NSString *)uuidString;

+ (NSDate *)getUTCDateFromMilliseconds:(double)timeInterval;

+ (NSString *)convertUTCDateForDate:(NSDate *)date;

+ (NSString *)deviceName;

+ (NSString *)resourcePath;

+ (id)getValidatedString:(NSString *)str;

+ (UIColor *)colorWithHexString:(NSString *)hexString;

+ (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

+ (UIColor *)colorWithHexString:(NSString *)hexString withOpacity:(CGFloat)opacity;

+ (CGFloat)getLabelHeight:(UILabel*)label;

+ (BOOL)getCurrnetDeviceOrientation;

+ (CGFloat)getLabelHeight:(UILabel*)label withWidth:(CGFloat)width;

+ (CGFloat)getContentSize:(NSString *)content width:(CGFloat)width;

+ (CGFloat)getContentSize:(NSString *)content width:(CGFloat)width andLabel:(UILabel *)label;

+ (CGFloat)getHeightWithDefaultLabel:(NSString *)content width:(CGFloat)width;

+ (void)doBubbleAnimationWithSubViews:(UIView *)view andbutton:(UIButton *)skipButton;

+ (CGFloat)getTextViewHeightDynamicallay:(UITextView *)textView withWidth:(CGFloat )width;

+ (UIImage *)convertLogoimage:(UIImage *)image convertToSize:(CGSize)size;

+ (BOOL)validateURL: (NSString *)url;

+ (NSString *)validateString:(NSString *)value;

+ (BOOL)currentDeviceisIpad;

+ (BOOL)hasNotch;

+ (BOOL)deviceisiPhone5;

+ (BOOL)deviceisiPhone4;

@end
