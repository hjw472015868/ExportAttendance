//
//  YXHDayAtt.h
//  ExportAttendance
//
//  Created by Apple on 2018/8/14.
//  Copyright © 2018年 xlware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YXHDayAtt : NSObject

/**
 当月第几天
 */
@property (nonatomic, copy) NSString *day;

/**
 当天出勤记录
 */
@property (nonatomic, strong) NSMutableArray<NSString *> *attRcod;

@end
