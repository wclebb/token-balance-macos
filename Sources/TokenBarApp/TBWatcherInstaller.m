#import "TBWatcherInstaller.h"
#import <unistd.h>

@implementation TBWatcherInstaller
+ (void)installForApplicationBundle:(NSBundle *)bundle {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSFileManager *files = NSFileManager.defaultManager;
        NSURL *bundledWatcher = [bundle URLForResource:@"Token Balance Watcher" withExtension:nil];
        if (!bundledWatcher) return;

        NSURL *supportRoot = [files URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        NSURL *support = [supportRoot URLByAppendingPathComponent:@"Token Balance" isDirectory:YES];
        NSURL *installedWatcher = [support URLByAppendingPathComponent:@"Token Balance Watcher"];
        NSURL *legacySupport = [supportRoot URLByAppendingPathComponent:@"TokenBar" isDirectory:YES];
        NSURL *legacyWatcher = [legacySupport URLByAppendingPathComponent:@"TokenBarWatcher"];
        NSError *error = nil;
        if (![files createDirectoryAtURL:support withIntermediateDirectories:YES attributes:nil error:&error]) return;
        [files removeItemAtURL:installedWatcher error:nil];
        if (![files copyItemAtURL:bundledWatcher toURL:installedWatcher error:&error]) return;
        [files setAttributes:@{NSFilePosixPermissions: @0755} ofItemAtPath:installedWatcher.path error:nil];

        NSURL *launchAgents = [[files URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].firstObject URLByAppendingPathComponent:@"LaunchAgents" isDirectory:YES];
        if (![files createDirectoryAtURL:launchAgents withIntermediateDirectories:YES attributes:nil error:&error]) return;
        NSURL *plistURL = [launchAgents URLByAppendingPathComponent:@"com.tokenbalance.watcher.plist"];
        NSURL *legacyPlistURL = [launchAgents URLByAppendingPathComponent:@"com.tokenbar.watcher.plist"];
        NSDictionary *plist = @{
            @"Label": @"com.tokenbalance.watcher",
            @"ProgramArguments": @[installedWatcher.path, bundle.bundlePath],
            @"RunAtLoad": @YES,
            @"KeepAlive": @YES,
            @"ProcessType": @"Background"
        };
        NSString *domain = [NSString stringWithFormat:@"gui/%u", getuid()];
        for (NSURL *installedPlist in @[plistURL, legacyPlistURL]) {
            NSTask *bootout = [NSTask new];
            bootout.executableURL = [NSURL fileURLWithPath:@"/bin/launchctl"];
            bootout.arguments = @[@"bootout", domain, installedPlist.path];
            bootout.standardOutput = [NSPipe pipe];
            bootout.standardError = [NSPipe pipe];
            [bootout launchAndReturnError:nil];
            [bootout waitUntilExit];
        }

        [files removeItemAtURL:legacyPlistURL error:nil];
        [files removeItemAtURL:legacyWatcher error:nil];
        if (![plist writeToURL:plistURL error:&error]) return;

        NSTask *bootstrap = [NSTask new];
        bootstrap.executableURL = [NSURL fileURLWithPath:@"/bin/launchctl"];
        bootstrap.arguments = @[@"bootstrap", domain, plistURL.path];
        bootstrap.standardOutput = [NSPipe pipe];
        bootstrap.standardError = [NSPipe pipe];
        [bootstrap launchAndReturnError:nil];
        [bootstrap waitUntilExit];
    });
}
@end
