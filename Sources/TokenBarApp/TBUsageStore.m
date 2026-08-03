#import "TBUsageStore.h"

@interface TBUsageStore ()
@property (nonatomic, strong, nullable) TBUsageSnapshot *snapshot;
@property (nonatomic, strong, nullable) NSError *lastError;
@property (nonatomic, getter=isRefreshing) BOOL refreshing;
@property (nonatomic, strong) id<TBUsageProvider> provider;
@property (nonatomic, strong, nullable) NSTimer *timer;
@end

@implementation TBUsageStore
- (instancetype)initWithProvider:(id<TBUsageProvider>)provider {
    if ((self = [super init])) {
        _provider = provider;
        _refreshInterval = 60;
    }
    return self;
}

- (void)start {
    [self refresh];
    [self scheduleTimer];
}

- (void)scheduleTimer {
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval target:self selector:@selector(refresh) userInfo:nil repeats:YES];
}

- (void)refresh {
    if (self.refreshing) return;
    self.refreshing = YES;
    [self.delegate usageStoreDidChange:self];
    __weak typeof(self) weakSelf = self;
    [self.provider fetchUsageWithCompletion:^(TBUsageSnapshot *snapshot, NSError *error) {
        typeof(self) self = weakSelf;
        if (!self) return;
        self.refreshing = NO;
        if (snapshot) {
            self.snapshot = snapshot;
            self.lastError = nil;
        } else {
            self.lastError = error ?: [NSError errorWithDomain:@"TokenBar.Store" code:1 userInfo:@{NSLocalizedDescriptionKey: @"无法自动读取 ChatGPT 额度。"}];
        }
        [self.delegate usageStoreDidChange:self];
    }];
}
@end
