/**
 * APICloud Modules
 * Copyright (c) 2014-2018 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import "UZPedometer.h"
#import "UZHealthStore.h"
#import "NSDictionaryUtils.h"
#import <HealthKit/HealthKit.h>

@implementation UZPedometer

- (void)getStepCount:(NSDictionary *)paramsDict_ {
    if ([UZHealthStore isHealthDataAvailable]) {
        //访问健康的对象
        UZHealthStore *healthStore = [UZHealthStore shareInstance];
        //获取的数据类型，步数（手机+手表）
        HKObjectType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        //获取数据类型的集合
        NSSet *healthSet = [NSSet setWithObject:stepCountType];
        //请求授权
        [healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSInteger count = [paramsDict_ integerValueForKey:@"count" defaultValue:0];
                NSString *startTime = [paramsDict_ stringValueForKey:@"startTime" defaultValue:@""];
                NSString *endTime = [paramsDict_ stringValueForKey:@"endTime" defaultValue:@""];
                BOOL remove = [paramsDict_ boolValueForKey:@"remove" defaultValue:false];
                int readStepCountCbId = [paramsDict_ intValueForKey:@"cbId" defaultValue:-1];
                if (startTime.length<1 || endTime.length<1) return ;

                //查询采样信息
                HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
                
                //NSSortDescriptors用来告诉healthStore怎么样将结果排序。
                NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
                NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
                //时间：开始-------------->结束------->
                NSDateFormatter *tempFormatter = [self setupCurrentDateFormatter];
                NSDate *currentStartDate  = [tempFormatter  dateFromString:startTime];
                NSDate *currentEndDate  = [tempFormatter  dateFromString:endTime];
                //开始时间往后推三天，超过三天则以三天为准
                NSTimeInterval threeDay = 3 * 60 * 60 *24;
                NSDate *endDate = [NSDate dateWithTimeInterval:threeDay sinceDate:currentStartDate];
                if ([currentEndDate compare:endDate] == NSOrderedDescending) {
                    currentEndDate = endDate;
                }
                
                //先生成一个断言，观察者根据断言去获取数据
                NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:currentStartDate endDate:currentEndDate options:HKQueryOptionNone];
                
                //观察者查询
                HKObserverQuery *observerQuery = [[HKObserverQuery alloc] initWithSampleType:sampleType predicate:predicate updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
                    if (!error) {
                        //样本查询
                        HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:count sortDescriptors:@[start,end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                            NSInteger total = 0;
                            NSString *beginTime = nil;
                            NSString *finishTime = nil;
                            NSMutableArray *detailArr = [NSMutableArray array];
                            NSDateFormatter *formatter = [self setupCurrentDateFormatter];
                            
                            for (NSUInteger i = 0; i < results.count; i++) {
                                HKQuantitySample *result = results[i];
                                //是否去掉人为添加的数据
                                if (remove) {
                                    NSInteger  userEntered =  [result.metadata[@"HKWasUserEntered"] integerValue];
                                    if (userEntered == 1) {
                                        result = nil;
                                    }
                                }
                                //装填、打包数据
                                NSMutableDictionary *detailDict = [NSMutableDictionary dictionary];
                                HKSource *source = result.source;
                                NSString *bundleIdentifier = source.bundleIdentifier;
                                NSString *name = source.name;
                                HKSourceRevision *sourceRevision = result.sourceRevision;
                                NSString *version = sourceRevision.version;
                                if (![bundleIdentifier isKindOfClass:[NSString class]] || bundleIdentifier.length==0) {
                                    bundleIdentifier = @"";
                                }
                                if (![name isKindOfClass:[NSString class]] || name.length==0) {
                                    name = @"";
                                }
                                if (![version isKindOfClass:[NSString class]] || version.length==0) {
                                    version = @"";
                                }
                                NSDictionary *sourceDict = @{@"name":name,@"version":version,@"bId":bundleIdentifier};
                                [detailDict setObject:sourceDict forKey:@"source"];
                                
                                HKDevice *device = result.device;
                                NSString *nameDe = device.name;
                                NSString *manufacturerDe = device.manufacturer;
                                NSString *modelDe = device.model;
                                NSString *hardwareVersionDe = device.hardwareVersion;
                                NSString *softwareVersionDe = device.softwareVersion;
                                if (![nameDe isKindOfClass:[NSString class]] || nameDe.length==0) {
                                    nameDe = @"";
                                }
                                if (![manufacturerDe isKindOfClass:[NSString class]] || manufacturerDe.length==0) {
                                    manufacturerDe = @"";
                                }
                                if (![modelDe isKindOfClass:[NSString class]] || modelDe.length==0) {
                                    modelDe = @"";
                                }
                                if (![hardwareVersionDe isKindOfClass:[NSString class]] || hardwareVersionDe.length==0) {
                                    hardwareVersionDe = @"";
                                }
                                if (![softwareVersionDe isKindOfClass:[NSString class]] || softwareVersionDe.length==0) {
                                    softwareVersionDe = @"";
                                }
                                NSDictionary *deviceDict = @{@"name":nameDe,@"manufacturer":manufacturerDe,@"model":modelDe,@"hardwareVersion":hardwareVersionDe,@"softwareVersion":softwareVersionDe};
                                [detailDict setObject:deviceDict forKey:@"device"];
                                
                                //步数
                                HKQuantity *quantity = result.quantity;
                                NSUInteger stepCount = (NSUInteger)[quantity doubleValueForUnit:[HKUnit unitFromString:@""]];
                                if (quantity) {
                                    [detailDict setObject:@(stepCount)forKey:@"stepCount"];
                                }
                                NSDate *startDate = result.startDate;
                                NSString *startTime = [formatter stringFromDate:startDate];
                                if (startDate) {
                                    [detailDict setObject:startTime forKey:@"startTime"];
                                }
                                NSDate *endDate = result.endDate;
                                NSString *endTime = [formatter stringFromDate:endDate];
                                if (endDate) {
                                    [detailDict setObject:endTime forKey:@"endTime"];
                                }
                                if (detailDict.count) {
                                    [detailArr addObject:detailDict];
                                }
                                total = total + stepCount;
                                
                                //最初开始时间
                                if (i == results.count - 1) {
                                    NSDate *beginDate = result.startDate;
                                    beginTime = [tempFormatter stringFromDate:beginDate];
                                }
                                
                                //最后结束时间
                                if (i == 0) {
                                    NSDate *finishDate = result.endDate;
                                    finishTime = [tempFormatter stringFromDate:finishDate];
                                }
                            }
                            //callback
                            NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
                            [sendDict setObject:@(total) forKey:@"total"];
                            
                            if (beginTime) {
                                [sendDict setObject:beginTime forKey:@"beginTime"];
                            }
                            
                            if (finishTime) {
                                [sendDict setObject:finishTime forKey:@"finishTime"];
                            }
                            if (detailArr) {
                                [sendDict setObject:detailArr forKey:@"details"];
                            }
                            [self sendResultEventWithCallbackId:readStepCountCbId dataDict:sendDict errDict:nil doDelete:YES];
                        }];
                        [healthStore executeQuery:sampleQuery];
                    }
                }];
                [healthStore executeQuery:observerQuery];
            }
        }];
    }
}

- (NSDateFormatter *)setupCurrentDateFormatter {
    NSDateFormatter *tempFormatter = [[NSDateFormatter alloc] init];
    [tempFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [tempFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
    return tempFormatter;
}

@end
