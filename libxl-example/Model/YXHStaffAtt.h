//
//  YXHStaffAtt.h
//  ExportAttendance
//
//  Created by Apple on 2018/8/14.
//  Copyright © 2018年 xlware. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YXHDayAtt;

@interface YXHStaffAtt : NSObject

/**
 工号
 */
@property (nonatomic, copy) NSString *staffNo;

/**
 当月所有出勤
 */
@property (nonatomic, strong) NSMutableArray<YXHDayAtt *> *days;

@end
