//
//  AppDelegate.h
//  libxl-example
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	NSWindow *window;
	NSMatrix *excelFormat;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMatrix *excelFormat;

- (IBAction)createExcel:(id)sender;

@end
