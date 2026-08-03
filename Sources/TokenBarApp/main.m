#import <Cocoa/Cocoa.h>
#import "TBAppDelegate.h"

int main(__unused int argc, __unused const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        TBAppDelegate *delegate = [TBAppDelegate new];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
