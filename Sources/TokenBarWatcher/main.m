#import <Cocoa/Cocoa.h>
#import "TokenBarCore.h"

static NSString *const TBChatGPTBundleID = @"com.openai.codex";
static NSString *const TBTokenBarBundleID = @"com.tokenbar.macos";

@interface TBWatcherDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) TBWatcherPolicy *policy;
@property (nonatomic, strong) NSURL *tokenBarURL;
@property (nonatomic) BOOL terminatingForChatGPT;
@end

@implementation TBWatcherDelegate
- (instancetype)initWithTokenBarURL:(NSURL *)tokenBarURL {
    if ((self = [super init])) {
        _tokenBarURL = tokenBarURL;
        _policy = [TBWatcherPolicy new];
    }
    return self;
}

- (BOOL)isRunning:(NSString *)bundleID {
    return [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID].count > 0;
}

- (void)performAction:(TBWatcherAction)action {
    if (action == TBWatcherActionLaunchTokenBar) {
        NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
        configuration.activates = NO;
        [NSWorkspace.sharedWorkspace openApplicationAtURL:self.tokenBarURL configuration:configuration completionHandler:^(__unused NSRunningApplication *application, __unused NSError *error) {}];
    } else if (action == TBWatcherActionTerminateTokenBar) {
        self.terminatingForChatGPT = YES;
        for (NSRunningApplication *application in [NSRunningApplication runningApplicationsWithBundleIdentifier:TBTokenBarBundleID]) [application terminate];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSNotificationCenter *center = NSWorkspace.sharedWorkspace.notificationCenter;
    [center addObserver:self selector:@selector(applicationLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [center addObserver:self selector:@selector(applicationTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    [self performAction:[self.policy initialActionWithChatGPTRunning:[self isRunning:TBChatGPTBundleID] tokenBarRunning:[self isRunning:TBTokenBarBundleID]]];
}

- (void)applicationLaunched:(NSNotification *)notification {
    NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
    if ([application.bundleIdentifier isEqualToString:TBChatGPTBundleID]) {
        [self performAction:[self.policy chatGPTDidLaunchWithTokenBarRunning:[self isRunning:TBTokenBarBundleID]]];
    }
}

- (void)applicationTerminated:(NSNotification *)notification {
    NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
    if ([application.bundleIdentifier isEqualToString:TBChatGPTBundleID]) {
        [self performAction:[self.policy chatGPTDidTerminateWithTokenBarRunning:[self isRunning:TBTokenBarBundleID]]];
    } else if ([application.bundleIdentifier isEqualToString:TBTokenBarBundleID]) {
        if (self.terminatingForChatGPT) {
            self.terminatingForChatGPT = NO;
        } else {
            [self.policy tokenBarDidTerminateWhileChatGPTRunning:[self isRunning:TBChatGPTBundleID]];
        }
    }
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 2) return 2;
        NSURL *tokenBarURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
        NSApplication *application = NSApplication.sharedApplication;
        [application setActivationPolicy:NSApplicationActivationPolicyProhibited];
        TBWatcherDelegate *delegate = [[TBWatcherDelegate alloc] initWithTokenBarURL:tokenBarURL];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
