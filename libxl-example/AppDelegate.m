//
//  AppDelegate.m
//  libxl-example
//

#import "AppDelegate.h"
#include "LibXL/libxl.h"

#import "YXHStaffAtt.h"
#import "YXHDayAtt.h"

#define kStaffNoColIndex 3
#define kBaseIndex 2
#define kRowHeight 25

@interface AppDelegate ()

@property (nonatomic, assign) FormatHandle titleFormat;
@property (nonatomic, assign) SheetHandle sourceSheet0;
@property (nonatomic, strong) NSMutableArray *staffTitleIndexList;

@property (nonatomic, strong) NSMutableArray *staffAttList;

@end

@implementation AppDelegate

@synthesize excelFormat;
@synthesize window;

- (NSMutableArray<YXHStaffAtt *> *)staffAttList {
    if (!_staffAttList) {
        _staffAttList = [NSMutableArray array];
    }
    return _staffAttList;
}

- (NSMutableArray *)staffTitleIndexList {
    if (!_staffTitleIndexList) {
        _staffTitleIndexList = [NSMutableArray array];
    }
    return _staffTitleIndexList;
}

- (id)init {
	[NSApp setDelegate:self];
	return self;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (void)dealloc {
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
}

- (IBAction)clearCache:(id)sender {
    [self setCacheWithLoc:0];
}

- (void)setCacheWithLoc:(NSInteger)loc {
    [[NSUserDefaults standardUserDefaults] setInteger:loc forKey:kLocKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)touchSelecteFileBtn:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    //是否可以创建文件夹
    panel.canCreateDirectories = NO;
    //是否可以选择文件夹
    panel.canChooseDirectories = NO;
    //是否可以选择文件
    panel.canChooseFiles = YES;
    //是否可以多选
    [panel setAllowsMultipleSelection:NO];
    //显示
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        //是否点击open 按钮
        if (result == NSModalResponseOK) {
            NSString *path = [[panel.URLs firstObject] path];
            NSLog(@"File path-->%@", path);
            [self readExcelFileWithPath:path];
        }
    }];
}

- (void)readExcelFileWithPath:(NSString *)path {
    NSLog(@"----start read file----");
    NSString *extensionStr = [path pathExtension];
//    NSLog(@"extensionStr-->%@", extensionStr);
    BOOL xlsMode = [extensionStr isEqualToString:kXLSExtension];
    BookHandle sourceBook;
    sourceBook = xlsMode ? xlCreateBook() : xlCreateXMLBook();
    BOOL loadBookSuccess = xlBookLoadA(sourceBook, [path UTF8String]);
    if (loadBookSuccess) {
        _sourceSheet0 = xlBookGetSheetA(sourceBook, 0);
        for (int i = 0; i < 200; i++) {
            int cellType = xlSheetCellTypeA(_sourceSheet0, i, 1);
            switch (cellType) {
                case CELLTYPE_BLANK:
//                    NSLog(@"%i -- %@",i + 1, @"CELLTYPE_BLANK");
//                    xlSheetReadBlankA(sheet, <#int row#>, <#int col#>, <#FormatHandle *format#>)
                    break;
                case CELLTYPE_EMPTY:
//                    NSLog(@"%i -- %@",i + 1, @"CELLTYPE_EMPTY");
                    break;
                case CELLTYPE_ERROR:
//                    NSLog(@"%i -- %@",i + 1, @"CELLTYPE_ERROR");
                    break;
                case CELLTYPE_NUMBER:
//                    NSLog(@"%i -- %@",i + 1, @"CELLTYPE_NUMBER");
                    break;
                case CELLTYPE_STRING: {
//                    NSLog(@"%i -- %@",i + 1, @"CELLTYPE_STRING");
                    const char *cStr = xlSheetReadStr(_sourceSheet0, i, 1, &_titleFormat);
                    NSString *ocStr = [NSString stringWithUTF8String:cStr];
//                    NSLog(@"%i -- %@",i + 1, ocStr);
                    if ([ocStr isEqualToString:@"???"]) {
                        [self.staffTitleIndexList addObject:@(i)];
                    }
                    break;
                }
                case CELLTYPE_BOOLEAN:
//                    NSLog(@"%i -- %@",i + 1, @"CELLTYPE_BOOLEAN");
                    break;
                    
                default:
                    break;
            }
        }
        [self checkStaffTitleIndexList];
    }
    xlBookRelease(sourceBook);
    NSLog(@"----read file completion----");
    [self createAttExcel];
}

- (void)checkStaffTitleIndexList {
    if (!self.staffTitleIndexList.count) return;
    NSInteger loc = [[NSUserDefaults standardUserDefaults] integerForKey:kLocKey];
    NSInteger length = 0;
    if ((loc / 10) == (self.staffTitleIndexList.count / 10)) {
        length = self.staffTitleIndexList.count % 10;
        [self clearCache:nil];
    } else {
        length = 10;
    }
    NSArray *subList = [self.staffTitleIndexList subarrayWithRange:NSMakeRange(loc, length)];
    int nextRowIndex = 0;
    for (NSInteger i = 0; i < subList.count; i++) {
        int rowIndex = [subList[i] intValue];
        if (i + 1 < subList.count) {
            // 存在下一个
            nextRowIndex = [subList[i + 1] intValue];
        } else {
            // 没有下一个
            if (length == 10) {
                nextRowIndex = [self.staffTitleIndexList[loc + length] intValue];
            } else {
                nextRowIndex += 4;
            }
        }
        [self readStaffNoWithRowIndex:rowIndex nextRowIndex:nextRowIndex];
    }
    loc += 10;
    if (loc > self.staffTitleIndexList.count) {
        loc = 0;
    }
    [self setCacheWithLoc:loc];
}

- (void)readStaffNoWithRowIndex:(int)rowIndex nextRowIndex:(int)nextRowIndex {
    int cellType = xlSheetCellTypeA(_sourceSheet0, rowIndex, kStaffNoColIndex);
    switch (cellType) {
        case CELLTYPE_BLANK:
//            NSLog(@"staffNo-->CELLTYPE_BLANK");
            break;
        case CELLTYPE_EMPTY:
//            NSLog(@"staffNo-->CELLTYPE_EMPTY");
            break;
        case CELLTYPE_ERROR:
//            NSLog(@"staffNo-->CELLTYPE_ERROR");
            break;
        case CELLTYPE_NUMBER:
//            NSLog(@"staffNo-->CELLTYPE_NUMBER");
            break;
        case CELLTYPE_STRING: {
            // 读取工号
            const char *cStr = xlSheetReadStr(_sourceSheet0, rowIndex, kStaffNoColIndex, &_titleFormat);
            NSString *staffNo = [NSString stringWithUTF8String:cStr];
//            NSLog(@"staffNo-->%@--CELLTYPE_STRING", staffNo);
            [self generationStaffAttInfoWithStaffNo:staffNo rowIndex:rowIndex nextRowIndex:nextRowIndex];
            break;
        }
        case CELLTYPE_BOOLEAN:
//            NSLog(@"staffNo-->CELLTYPE_BOOLEAN");
            break;
            
        default:
            break;
    }
}

- (void)generationStaffAttInfoWithStaffNo:(NSString *)staffNo rowIndex:(int)rowIndex nextRowIndex:(int)nextRowIndex {
    YXHStaffAtt *staffAtt = [[YXHStaffAtt alloc] init];
    staffAtt.staffNo = staffNo;
    staffAtt.days = [NSMutableArray array];
    int timeStartRow = rowIndex + 2;
    int timeEndRow = nextRowIndex - 1;
    // 此处可根据当月天数来遍历
    NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSRange range = [calendar rangeOfUnit:NSDayCalendarUnit inUnit: NSMonthCalendarUnit forDate:[NSDate date]];
    for (int col = 1; col <= range.length; col++) {
        YXHDayAtt *dayAtt = [[YXHDayAtt alloc] init];
        dayAtt.day = [NSString stringWithFormat:@"%i", col];
        dayAtt.attRcod = [NSMutableArray array];
        for (int row = timeStartRow; row <= timeEndRow; row++) {
//            NSLog(@"row = %i, col = %i", row, col);
            int cellType = xlSheetCellTypeA(_sourceSheet0, row, col);
            switch (cellType) {
                case CELLTYPE_NUMBER:
                case CELLTYPE_STRING: {
                    const char *cStr = xlSheetReadStr(_sourceSheet0, row, col, &_titleFormat);
//                    NSLog(@"cStr->%s", cStr);
                    NSString *timeStr = [NSString stringWithUTF8String:cStr];
                    [dayAtt.attRcod addObjectsFromArray:[timeStr componentsSeparatedByString:@"\n"]];
                    if ([dayAtt.attRcod.lastObject containsString:@" "]) [dayAtt.attRcod removeLastObject];
                    break;
                }
                    
                default:
                    break;
            }
        }
        [staffAtt.days addObject:dayAtt];
//        sleep(1);
    }
    [self.staffAttList addObject:staffAtt];
//    NSLog(@"staffAtt = %@", staffAtt);
//    [self printStaffAtt:staffAtt];
}

- (void)createAttExcel {
    NSLog(@"----start write data to file----");
//    NSLog(@"self.staffAttList = %@", self.staffAttList);
    SheetHandle targetSheet;
    BookHandle targetBook;
    targetBook = xlCreateXMLBook();
    targetSheet = xlBookAddSheet(targetBook, "staffAtt", 0);
    FormatHandle staffNoFormat;
    staffNoFormat = xlBookAddFormat(targetBook, 0);
    xlFormatSetAlignH(staffNoFormat, ALIGNH_CENTER);
    xlFormatSetAlignV(staffNoFormat, ALIGNV_CENTER);
    FormatHandle staffAttStatusFormat;
    staffAttStatusFormat = xlBookAddFormat(targetBook, 0);
    xlFormatSetAlignH(staffAttStatusFormat, ALIGNH_CENTER);
    xlFormatSetAlignV(staffAttStatusFormat, ALIGNV_JUSTIFY);
    if(targetSheet) {
        for (NSInteger i = 0; i < self.staffAttList.count; i++) {
            YXHStaffAtt *staffAtt = self.staffAttList[i];
            const char *staffNo = [staffAtt.staffNo UTF8String];
//            xlSheetSetRowA(SheetHandle handle, int row, double height, FormatHandle format, int hidden);
            // 设置行高
            xlSheetSetRow(targetSheet, (int)(i + kBaseIndex), kRowHeight, NULL, false);
            // 写入工号
            xlSheetWriteStr(targetSheet, (int)(i + kBaseIndex), kStaffNoColIndex, staffNo, staffNoFormat);
            // 写入考勤状态
            for (NSInteger j = 0; j < staffAtt.days.count; j++) {
                int row = (int)(i + kBaseIndex);
                int col = (int)(kStaffNoColIndex + 1 + j);
                YXHDayAtt *day = staffAtt.days[j];
                const char *cAttStatus = [self attStatusWithDay:day];
                xlSheetWriteStr(targetSheet, row, col, cAttStatus, staffAttStatusFormat);
            }
        }
        // 写入日期
        [self writeDay:self.staffAttList[0] targetSheet:targetSheet format:staffNoFormat];
    }
    NSString *name = @"targetBook.xlsx";
    NSString *documentPath =
    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filename = [documentPath stringByAppendingPathComponent:name];
    xlBookSave(targetBook, [filename UTF8String]);
    xlBookRelease(targetBook);
    [[NSWorkspace sharedWorkspace] openFile:filename];
    NSLog(@"----write to file completion----");
}

- (const char *)attStatusWithDay:(YXHDayAtt *)day {
    //    NSDate *date = [NSDate dateFromString:@"2018-08-17" format:@"yyyy-MM-dd"];
    //    NSLog(@"date = %@", date);
    //    NSString *dateStr = [NSDate dateStrFromDate:[NSDate date] withDateFormat:@"yyyy-MM-dd"];
    //    NSLog(@"dateStr = %@", dateStr);
    
    NSDate *date09 = [NSDate get09P];
    NSDate *date12 = [NSDate get12P];
    NSDate *date18 = [NSDate get18P];
    NSString *attStatus = nil;
    if (day.attRcod.count == 0) {
        attStatus = @"X\nX";
    } else if (day.attRcod.count == 1) {
        NSString *timeStr = [day.attRcod firstObject];
        NSString *attDateStr = [NSString stringWithFormat:@"2018-01-01 %@", timeStr];
        NSDate *attDate = [NSDate dateFromString:attDateStr format:@"yyyy-MM-dd HH:mm"];
//        NSLog(@"attDate = %@", attDate);
//        NSLog(@"date12 = %@", date12);
        BOOL a = [attDate isEarlierThanDate:date12];
//        NSLog(@"a = %zd", a);
        if ([attDate isEarlierThanDate:date12] || [attDate isEqualToDate:date12]) {
            if ([attDate isEarlierThanDate:date09] || [attDate isEqualToDate:date09]) {
                // 上班正常
                attStatus = @"OK\nX";
            } else {
                // 上班迟到
                attStatus = @"come late\nX";
            }
        } else {
            if ([attDate isEarlierThanDate:date18]) {
                // 下班早退
                attStatus = @"X\nleave early";
            } else {
                // 下班正常
                attStatus = @"X\nOK";
            }
        }
    } else {
//      所有的2018-01-01都是随便写的
        NSString *firstTimeStr = [day.attRcod firstObject];
        NSString *firstAttDateStr = [NSString stringWithFormat:@"2018-01-01 %@", firstTimeStr];
        NSDate *firstAttDate = [NSDate dateFromString:firstAttDateStr format:@"yyyy-MM-dd HH:mm"];
        
        NSString *lastTimeStr = [day.attRcod lastObject];
        NSString *lastAttDateStr = [NSString stringWithFormat:@"2018-01-01 %@", lastTimeStr];
        NSDate *lastAttDate = [NSDate dateFromString:lastAttDateStr format:@"yyyy-MM-dd HH:mm"];
        NSString *firstStr = nil;
        NSString *lastStr = nil;
        // 计算上午时间
        if ([firstAttDate isEarlierThanDate:date09] || [firstAttDate isEqualToDate:date09]) {
            // time <= 9 正常上班
            firstStr = @"OK";
        } else if ([firstAttDate isLaterThanDate:date09] && ([firstAttDate isEarlierThanDate:date12] || [firstAttDate isEqualToDate:date12])) {
            // 9 < time <= 12 迟到
            firstStr = @"come late";
        } else {
            // 上午缺勤
            firstStr = @"X";
        }
        // 计算下午时间
        if ([lastAttDate isEarlierThanDate:date18] && ([lastAttDate isLaterThanDate:date12] || [lastAttDate isEqualToDate:date12])) {
            // 12 <= time < 18 早退
            lastStr = @"leave early";
        } else if ([lastAttDate isLaterThanDate:date18] || [lastAttDate isEqualToDate:date18]) {
            // time >= 18 正常下班
            lastStr = @"OK";
        } else {
            // 下午缺勤
            lastStr = @"X";
        }
        attStatus = [NSString stringWithFormat:@"%@\n%@", firstStr, lastStr];
    }
    return [attStatus UTF8String];
}

- (void)writeDay:(YXHStaffAtt *)staffAtt targetSheet:(SheetHandle)targetSheet format:(FormatHandle)format {
//    NSLog(@"%s", __func__);
    int row = kBaseIndex - 1;
    for (NSInteger i = 0; i < staffAtt.days.count; i++) {
        YXHDayAtt *day = staffAtt.days[i];
        int col = (int)(kStaffNoColIndex + 1 + i);
        // 写入日期
        xlSheetWriteStr(targetSheet, row, col, [day.day UTF8String], format);
    }
}

- (void)printStaffAtt:(YXHStaffAtt *)staffAtt {
    NSLog(@"========");
    NSLog(@"staffNo = %@", staffAtt.staffNo);
    for (int i = 0; i < staffAtt.days.count; i++) {
        YXHDayAtt *dayAtt = staffAtt.days[i];
        NSLog(@"day = %@", dayAtt.day);
        for (NSInteger j = 0; j < dayAtt.attRcod.count; j++) {
            NSLog(@"time = %@", dayAtt.attRcod[j]);
        }
    }
}

- (IBAction)createExcel:(id)sender
{
    BOOL xlsMode = [[excelFormat selectedCell] tag];

    NSLog(@"createExcel: %@ mode", xlsMode ? @"xls" : @"xlsx");
    
    FontHandle boldFont;
    FontHandle titleFont;
    FormatHandle titleFormat;
    FormatHandle headerFormat;
    FormatHandle descriptionFormat;
    FormatHandle amountFormat;
    FormatHandle totalLabelFormat;
    FormatHandle totalFormat;
    FormatHandle signatureFormat;
    SheetHandle sheet;
    BookHandle book;
    
    book = xlsMode ? xlCreateBook() : xlCreateXMLBook();

    boldFont = xlBookAddFont(book, 0);
    xlFontSetBold(boldFont, 1);
    
    titleFont = xlBookAddFont(book, 0);
    xlFontSetName(titleFont, "Arial Black");
    xlFontSetSize(titleFont, 16);
    
    titleFormat = xlBookAddFormat(book, 0);
    xlFormatSetFont(titleFormat, titleFont);
        
    headerFormat = xlBookAddFormat(book, 0);
    xlFormatSetAlignH(headerFormat, ALIGNH_CENTER);
    xlFormatSetBorder(headerFormat, BORDERSTYLE_THIN);
    xlFormatSetFont(headerFormat, boldFont);
    xlFormatSetFillPattern(headerFormat, FILLPATTERN_SOLID);
    xlFormatSetPatternForegroundColor(headerFormat, COLOR_TAN);
    
    descriptionFormat = xlBookAddFormat(book, 0);
    xlFormatSetBorderLeft(descriptionFormat, BORDERSTYLE_THIN);
    
    amountFormat = xlBookAddFormat(book, 0);
    xlFormatSetNumFormat(amountFormat, NUMFORMAT_CURRENCY_NEGBRA);
    xlFormatSetBorderLeft(amountFormat, BORDERSTYLE_THIN);
    xlFormatSetBorderRight(amountFormat, BORDERSTYLE_THIN);
    
    totalLabelFormat = xlBookAddFormat(book, 0);
    xlFormatSetBorderTop(totalLabelFormat, BORDERSTYLE_THIN);
    xlFormatSetAlignH(totalLabelFormat, ALIGNH_RIGHT);
    xlFormatSetFont(totalLabelFormat, boldFont);
    
    totalFormat = xlBookAddFormat(book, 0);
    xlFormatSetNumFormat(totalFormat, NUMFORMAT_CURRENCY_NEGBRA);
    xlFormatSetBorder(totalFormat, BORDERSTYLE_THIN);
    xlFormatSetFont(totalFormat, boldFont);
    xlFormatSetFillPattern(totalFormat, FILLPATTERN_SOLID);
    xlFormatSetPatternForegroundColor(totalFormat, COLOR_YELLOW);
    
    signatureFormat = xlBookAddFormat(book, 0);
    xlFormatSetAlignH(signatureFormat, ALIGNH_CENTER);
    xlFormatSetBorderTop(signatureFormat, BORDERSTYLE_THIN);
         
    sheet = xlBookAddSheet(book, "Invoice", 0);
    if(sheet)
    {
        xlSheetWriteStr(sheet, 2, 1, "Invoice No. 3568", titleFormat);
        
        xlSheetWriteStr(sheet, 4, 1, "Name: John Smith", NULL);
        xlSheetWriteStr(sheet, 5, 1, "Address: San Ramon, CA 94583 USA", 0);
        
        xlSheetWriteStr(sheet, 7, 1, "Description", headerFormat);
        xlSheetWriteStr(sheet, 7, 2, "Amount", headerFormat);
        
        xlSheetWriteStr(sheet, 8, 1, "Ball-Point Pens", descriptionFormat);
        xlSheetWriteNum(sheet, 8, 2, 85, amountFormat);
        xlSheetWriteStr(sheet, 9, 1, "T-Shirts", descriptionFormat);
        xlSheetWriteNum(sheet, 9, 2, 150, amountFormat);
        xlSheetWriteStr(sheet, 10, 1, "Tea cups", descriptionFormat);
        xlSheetWriteNum(sheet, 10, 2, 45, amountFormat);
        
        xlSheetWriteStr(sheet, 11, 1, "Total:", totalLabelFormat);
        xlSheetWriteFormula(sheet, 11, 2, "=SUM(C9:C11)", totalFormat);
        
        xlSheetWriteStr(sheet, 14, 2, "Signature", signatureFormat);
        
        xlSheetSetCol(sheet, 1, 1, 40, 0, 0);
        xlSheetSetCol(sheet, 2, 2, 15, 0, 0);
    }
    
    NSString *name = xlsMode ? @"invoice.xls" : @"invoice.xlsx";
    NSString *documentPath =
    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filename = [documentPath stringByAppendingPathComponent:name];
    
    xlBookSave(book, [filename UTF8String]);
    
    xlBookRelease(book);
    
    [[NSWorkspace sharedWorkspace] openFile:filename];
}

@end
