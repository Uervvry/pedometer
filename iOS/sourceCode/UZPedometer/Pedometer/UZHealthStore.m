/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import "UZHealthStore.h"

@implementation UZHealthStore

static UZHealthStore *healthStore = nil;

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        healthStore  = [[UZHealthStore alloc] init];

    });
    return healthStore;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    @synchronized(self) {
        if (healthStore == nil) {
            healthStore = [super allocWithZone:zone];
        }
        return healthStore;
    }
    return nil;
}

@end
