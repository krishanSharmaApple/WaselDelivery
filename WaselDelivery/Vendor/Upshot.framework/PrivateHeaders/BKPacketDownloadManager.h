//
//  BKPacketDownloadManager.h
//  BrandKinesis
//
//  Created by Anand on 17/08/15.
//  Copyright (c) 2015 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>






@interface BKPacketDownloadManager : NSObject


typedef void(^BKDownloadCompletionBlock)(BKActivity *activity, NSError *error, BKPacketDownloadManager *manager);



- (void)downloadPacketWithURL:(NSURL *)url
                  forActivity:(BKActivity *)activity
                     fileName:(NSString *)fileName
          withCompletionBlock:(BKDownloadCompletionBlock)block;

- (void)copyPacketToLocalPath;

- (NSString *)getBrandKinesisFolderPath;

- (NSString *)getPathForFolder:(NSString *)folderName;

- (NSString *)getTutorialsPath;

+ (BKPacketDownloadManager *)sharedManager;

- (void)removeContentsFolder;

- (void)removeFolderFromBrandKinesisForFileName:(NSString *)fileName;

- (BOOL)fileExistsAtBrandKinesisPath:(NSString *)fileName;

@end
