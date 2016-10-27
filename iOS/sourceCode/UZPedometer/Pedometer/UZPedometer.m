/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
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
        UZHealthStore *healthStore = [UZHealthStore shareInstance];
        HKObjectType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        NSSet *healthSet = [NSSet setWithObject:stepCountType];
        //请求授权
        [healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSInteger count = [paramsDict_ integerValueForKey:@"count" defaultValue:0];
                NSString *startTime = [paramsDict_ stringValueForKey:@"startTime" defaultValue:@""];
                NSString *endTime = [paramsDict_ stringValueForKey:@"endTime" defaultValue:@""];
                BOOL remove = [paramsDict_ boolValueForKey:@"remove" defaultValue:false];
                int readStepCountCbId = [paramsDict_ intValueForKey:@"cbId" defaultValue:-1];
                if (startTime.length < 1 || endTime.length < 1) return ;

                //查询采样信息
                HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
                
                //NSSortDescriptors用来告诉healthStore怎么样将结果排序。
                NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
                NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];

                NSDateFormatter *tempFormatter = [self setupCurrentDateFormatter];
                NSDate *currentStartDate  = [tempFormatter  dateFromString:startTime];
                NSDate *currentEndDate  = [tempFormatter  dateFromString:endTime];
                
                NSTimeInterval threeDay = 3 * 60 * 60 *24;
                NSDate *endDate = [NSDate dateWithTimeInterval:threeDay sinceDate:currentStartDate];
                if ([currentEndDate compare:endDate] == NSOrderedDescending) {
                    currentEndDate = endDate;
                }
                
                //predicate
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
                                
                                //步数
                                HKQuantity *quantity = result.quantity;
                                NSUInteger stepCount = (NSUInteger)[quantity doubleValueForUnit:[HKUnit unitFromString:@""]];
                                NSMutableDictionary *detailDict = [NSMutableDictionary dictionary];
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
