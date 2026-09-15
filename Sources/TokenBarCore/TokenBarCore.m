#import "TokenBarCore.h"

@interface TBWatcherPolicy ()
@property (nonatomic, getter=isSuppressedUntilNextChatGPTLaunch) BOOL suppressedUntilNextChatGPTLaunch;
@end

@implementation TBWatcherPolicy
- (TBWatcherAction)initialActionWithChatGPTRunning:(BOOL)chatGPTRunning tokenBarRunning:(BOOL)tokenBarRunning {
    return chatGPTRunning && !tokenBarRunning ? TBWatcherActionLaunchTokenBar : TBWatcherActionNone;
}
- (TBWatcherAction)chatGPTDidLaunchWithTokenBarRunning:(BOOL)tokenBarRunning {
    if (self.suppressedUntilNextChatGPTLaunch) return TBWatcherActionNone;
    return tokenBarRunning ? TBWatcherActionNone : TBWatcherActionLaunchTokenBar;
}
- (TBWatcherAction)chatGPTDidTerminateWithTokenBarRunning:(BOOL)tokenBarRunning {
    self.suppressedUntilNextChatGPTLaunch = NO;
    return tokenBarRunning ? TBWatcherActionTerminateTokenBar : TBWatcherActionNone;
}
- (void)tokenBarDidTerminateWhileChatGPTRunning:(BOOL)chatGPTRunning {
    if (chatGPTRunning) self.suppressedUntilNextChatGPTLaunch = YES;
}
@end

@implementation TBExtraReset
- (instancetype)initWithID:(NSString *)identifier expiresAt:(NSDate *)expiresAt {
    if ((self = [super init])) {
        _identifier = [identifier copy];
        _expiresAt = expiresAt;
    }
    return self;
}
@end

@implementation TBUsageSnapshot
- (instancetype)initWithProviderID:(NSString *)providerID
                  percentRemaining:(NSNumber *)percentRemaining
                     usesRemaining:(NSNumber *)usesRemaining
                          resetsAt:(NSDate *)resetsAt
                       extraResets:(NSArray<TBExtraReset *> *)extraResets
                        capturedAt:(NSDate *)capturedAt {
    return [self initWithProviderID:providerID percentRemaining:percentRemaining usesRemaining:usesRemaining resetsAt:resetsAt extraResets:extraResets extraResetCount:extraResets.count capturedAt:capturedAt];
}
- (instancetype)initWithProviderID:(NSString *)providerID
                  percentRemaining:(NSNumber *)percentRemaining
                     usesRemaining:(NSNumber *)usesRemaining
                          resetsAt:(NSDate *)resetsAt
                       extraResets:(NSArray<TBExtraReset *> *)extraResets
                   extraResetCount:(NSInteger)extraResetCount
                        capturedAt:(NSDate *)capturedAt {
    return [self initWithProviderID:providerID percentRemaining:percentRemaining usesRemaining:usesRemaining resetsAt:resetsAt fiveHourPercentRemaining:nil fiveHourResetsAt:nil extraResets:extraResets extraResetCount:extraResetCount capturedAt:capturedAt];
}
- (instancetype)initWithProviderID:(NSString *)providerID
                  percentRemaining:(NSNumber *)percentRemaining
                     usesRemaining:(NSNumber *)usesRemaining
                          resetsAt:(NSDate *)resetsAt
          fiveHourPercentRemaining:(NSNumber *)fiveHourPercentRemaining
                  fiveHourResetsAt:(NSDate *)fiveHourResetsAt
                       extraResets:(NSArray<TBExtraReset *> *)extraResets
                   extraResetCount:(NSInteger)extraResetCount
                        capturedAt:(NSDate *)capturedAt {
    if ((self = [super init])) {
        _fiveHourPercentRemaining = fiveHourPercentRemaining;
        _fiveHourResetsAt = fiveHourResetsAt;
        _providerID = [providerID copy];
        _percentRemaining = percentRemaining;
        _usesRemaining = usesRemaining;
        _resetsAt = resetsAt;
        _extraResets = [extraResets copy];
        _extraResetCount = MAX(0, extraResetCount);
        _capturedAt = capturedAt;
    }
    return self;
}
@end

@implementation TBMenuBarLabel
- (instancetype)initWithText:(NSString *)text kind:(TBMenuBarLabelKind)kind stale:(BOOL)stale {
    if ((self = [super init])) {
        _text = [text copy];
        _kind = kind;
        _stale = stale;
    }
    return self;
}
@end

@implementation TBMenuBarFormatter
+ (NSString *)shortDurationFrom:(NSDate *)now to:(NSDate *)future {
    NSTimeInterval seconds = MAX(0, [future timeIntervalSinceDate:now]);
    if (seconds >= 86400) return [NSString stringWithFormat:@"%ldd", (long)ceil(seconds / 86400.0)];
    if (seconds >= 3600) return [NSString stringWithFormat:@"%ldh", (long)ceil(seconds / 3600.0)];
    return [NSString stringWithFormat:@"%ldm", (long)MAX(1, ceil(seconds / 60.0))];
}

+ (TBMenuBarLabel *)labelForSnapshot:(TBUsageSnapshot *)snapshot
                                 now:(NSDate *)now
                      alertThreshold:(NSTimeInterval)alertThreshold {
    NSString *percent = snapshot.percentRemaining ? [NSString stringWithFormat:@"%@%%", snapshot.percentRemaining] : @"—%";
    NSString *fiveHour = snapshot.fiveHourPercentRemaining ? [NSString stringWithFormat:@"%@%%", snapshot.fiveHourPercentRemaining] : @"—%";
    NSArray<TBExtraReset *> *expiring = [snapshot.extraResets filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TBExtraReset *reset, __unused NSDictionary *_) {
        NSTimeInterval remaining = [reset.expiresAt timeIntervalSinceDate:now];
        return remaining >= 0 && remaining <= alertThreshold;
    }]];
    TBMenuBarLabelKind kind = TBMenuBarLabelKindNormal;
    NSString *tail = @"";
    if (expiring.count > 0) {
        TBExtraReset *soonest = [expiring sortedArrayUsingComparator:^NSComparisonResult(TBExtraReset *a, TBExtraReset *b) {
            return [a.expiresAt compare:b.expiresAt];
        }].firstObject;
        tail = [NSString stringWithFormat:@" · ⚠ R %@", [self shortDurationFrom:now to:soonest.expiresAt]];
        kind = TBMenuBarLabelKindWarning;
    }
    BOOL stale = [now timeIntervalSinceDate:snapshot.capturedAt] > 7200;
    NSString *text = [NSString stringWithFormat:@"5H %@ · W %@ · R×%ld%@%@", fiveHour, percent, (long)snapshot.extraResetCount, tail, stale ? @" ↻" : @""];
    return [[TBMenuBarLabel alloc] initWithText:text kind:kind stale:stale];
}
@end

static id TBFirstValue(NSDictionary *dictionary, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = dictionary[key];
        if (value && value != NSNull.null) return value;
    }
    return nil;
}

static NSDate *TBDateFromValue(id value) {
    if ([value isKindOfClass:NSDate.class]) return value;
    if ([value isKindOfClass:NSNumber.class]) return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
    if (![value isKindOfClass:NSString.class]) return nil;
    static NSISO8601DateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ formatter = [NSISO8601DateFormatter new]; });
    return [formatter dateFromString:value];
}

@implementation TBChatGPTSnapshotParser
+ (TBUsageSnapshot *)snapshotFromData:(NSData *)data error:(NSError **)error {
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![root isKindOfClass:NSDictionary.class]) {
        if (error && !*error) *error = [NSError errorWithDomain:@"TokenBar.Parser" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Usage snapshot must be a JSON object."}];
        return nil;
    }
    NSDictionary *json = root;
    NSDictionary *weekly = TBFirstValue(json, @[@"weekly", @"weekly_limit"]);
    if (![weekly isKindOfClass:NSDictionary.class]) weekly = @{};
    NSNumber *percent = TBFirstValue(weekly, @[@"percentRemaining", @"percent_remaining", @"remainingPercent", @"remaining_percent"]);
    NSNumber *uses = TBFirstValue(weekly, @[@"usesRemaining", @"uses_remaining", @"remainingUses", @"remaining_uses"]);
    id resetValue = TBFirstValue(weekly, @[@"resetsAt", @"resets_at", @"resetAt", @"reset_at"]);
    NSDate *resetsAt = TBDateFromValue(resetValue);
    if (resetValue && !resetsAt) {
        if (error) *error = [NSError errorWithDomain:@"TokenBar.Parser" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Weekly reset date is invalid."}];
        return nil;
    }
    NSArray *rawResets = TBFirstValue(json, @[@"extraResets", @"extra_resets"]);
    NSMutableArray<TBExtraReset *> *extraResets = [NSMutableArray array];
    if ([rawResets isKindOfClass:NSArray.class]) {
        for (NSDictionary *raw in rawResets) {
            if (![raw isKindOfClass:NSDictionary.class]) continue;
            NSString *identifier = TBFirstValue(raw, @[@"id", @"identifier"]);
            id expiryValue = TBFirstValue(raw, @[@"expiresAt", @"expires_at"]);
            NSDate *expiry = TBDateFromValue(expiryValue);
            if (expiry) [extraResets addObject:[[TBExtraReset alloc] initWithID:identifier ?: NSUUID.UUID.UUIDString expiresAt:expiry]];
        }
    }
    id capturedValue = TBFirstValue(json, @[@"capturedAt", @"captured_at", @"updatedAt", @"updated_at"]);
    NSDate *capturedAt = TBDateFromValue(capturedValue) ?: NSDate.date;
    NSString *provider = TBFirstValue(json, @[@"provider", @"providerID", @"provider_id"]) ?: @"chatgpt";
    return [[TBUsageSnapshot alloc] initWithProviderID:provider percentRemaining:percent usesRemaining:uses resetsAt:resetsAt extraResets:extraResets capturedAt:capturedAt];
}
@end


static NSNumber *TBRemainingPercent(NSDictionary *window) {
    NSNumber *used = window[@"usedPercent"];
    if (![used isKindOfClass:NSNumber.class] || !isfinite(used.doubleValue)) return nil;
    return @(MAX(0, MIN(100, 100 - used.doubleValue)));
}

@implementation TBCodexRateLimitParser
+ (TBUsageSnapshot *)snapshotFromResponseData:(NSData *)data capturedAt:(NSDate *)capturedAt error:(NSError **)error {
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![root isKindOfClass:NSDictionary.class]) return nil;
    NSDictionary *response = root;
    NSDictionary *result = response[@"result"];
    if (![result isKindOfClass:NSDictionary.class]) {
        NSString *message = [response[@"error"] isKindOfClass:NSDictionary.class] ? response[@"error"][@"message"] : nil;
        if (error) *error = [NSError errorWithDomain:@"TokenBar.AppServer" code:2 userInfo:@{NSLocalizedDescriptionKey: message ?: @"ChatGPT 未返回额度数据。"}];
        return nil;
    }
    NSDictionary *snapshotJSON = [result[@"rateLimitsByLimitId"] isKindOfClass:NSDictionary.class] ? result[@"rateLimitsByLimitId"][@"codex"] : nil;
    if (![snapshotJSON isKindOfClass:NSDictionary.class]) snapshotJSON = result[@"rateLimits"];
    if (![snapshotJSON isKindOfClass:NSDictionary.class]) {
        if (error) *error = [NSError errorWithDomain:@"TokenBar.AppServer" code:3 userInfo:@{NSLocalizedDescriptionKey: @"当前账户没有可用的 ChatGPT/Codex 额度窗口。"}];
        return nil;
    }
    NSDictionary *primary = [snapshotJSON[@"primary"] isKindOfClass:NSDictionary.class] ? snapshotJSON[@"primary"] : nil;
    NSDictionary *secondary = [snapshotJSON[@"secondary"] isKindOfClass:NSDictionary.class] ? snapshotJSON[@"secondary"] : nil;
    // Slot order varies by account: identify windows by duration, never by position.
    NSDictionary *weekly = nil;
    NSDictionary *fiveHour = nil;
    for (NSDictionary *window in @[primary ?: @{}, secondary ?: @{}]) {
        NSNumber *duration = window[@"windowDurationMins"];
        if (![duration isKindOfClass:NSNumber.class]) continue;
        if (duration.doubleValue == 10080) weekly = window;
        if (duration.doubleValue == 300) fiveHour = window;
    }
    NSNumber *percentRemaining = TBRemainingPercent(weekly);
    NSDate *resetsAt = TBDateFromValue(weekly[@"resetsAt"]);
    NSNumber *fiveHourPercent = TBRemainingPercent(fiveHour);
    NSDate *fiveHourResetsAt = TBDateFromValue(fiveHour[@"resetsAt"]);

    NSDictionary *creditSummary = [result[@"rateLimitResetCredits"] isKindOfClass:NSDictionary.class] ? result[@"rateLimitResetCredits"] : nil;
    NSArray *credits = [creditSummary[@"credits"] isKindOfClass:NSArray.class] ? creditSummary[@"credits"] : @[];
    NSMutableArray<TBExtraReset *> *resets = [NSMutableArray array];
    for (NSDictionary *credit in credits) {
        if (![credit isKindOfClass:NSDictionary.class] || ![credit[@"status"] isEqual:@"available"] || ![credit[@"expiresAt"] isKindOfClass:NSNumber.class]) continue;
        NSString *identifier = [credit[@"id"] isKindOfClass:NSString.class] ? credit[@"id"] : NSUUID.UUID.UUIDString;
        [resets addObject:[[TBExtraReset alloc] initWithID:identifier expiresAt:[NSDate dateWithTimeIntervalSince1970:[credit[@"expiresAt"] doubleValue]]]];
    }
    NSInteger availableCount = [creditSummary[@"availableCount"] isKindOfClass:NSNumber.class] ? [creditSummary[@"availableCount"] integerValue] : resets.count;
    return [[TBUsageSnapshot alloc] initWithProviderID:@"chatgpt" percentRemaining:percentRemaining usesRemaining:nil resetsAt:resetsAt fiveHourPercentRemaining:fiveHourPercent fiveHourResetsAt:fiveHourResetsAt extraResets:resets extraResetCount:availableCount capturedAt:capturedAt];
}
@end

@implementation TBCodexAppServerProvider
- (instancetype)init {
    if ((self = [super init])) _providerID = @"chatgpt";
    return self;
}

- (NSURL *)codexExecutableURL {
    NSArray<NSString *> *paths = @[
        @"/Applications/ChatGPT.app/Contents/Resources/codex",
        @"/opt/homebrew/bin/codex",
        @"/usr/local/bin/codex"
    ];
    for (NSString *path in paths) if ([NSFileManager.defaultManager isExecutableFileAtPath:path]) return [NSURL fileURLWithPath:path];
    return nil;
}

- (void)fetchUsageWithCompletion:(void (^)(TBUsageSnapshot *, NSError *))completion {
    NSURL *executable = [self codexExecutableURL];
    if (!executable) {
        NSError *error = [NSError errorWithDomain:@"TokenBar.AppServer" code:10 userInfo:@{NSLocalizedDescriptionKey: @"未找到 ChatGPT/Codex 桌面应用。"}];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
        return;
    }
    NSTask *task = [NSTask new];
    task.executableURL = executable;
    task.arguments = @[@"app-server", @"--stdio"];
    NSPipe *input = [NSPipe pipe];
    NSPipe *output = [NSPipe pipe];
    task.standardInput = input;
    task.standardOutput = output;
    task.standardError = [NSPipe pipe];
    NSMutableData *buffer = [NSMutableData data];
    __block BOOL finished = NO;
    void (^finish)(TBUsageSnapshot *, NSError *) = ^(TBUsageSnapshot *snapshot, NSError *error) {
        @synchronized (task) {
            if (finished) return;
            finished = YES;
        }
        output.fileHandleForReading.readabilityHandler = nil;
        if (task.isRunning) [task terminate];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(snapshot, error); });
    };
    output.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *chunk = handle.availableData;
        if (chunk.length == 0) return;
        [buffer appendData:chunk];
        while (YES) {
            const uint8_t *bytes = buffer.bytes;
            NSUInteger newline = NSNotFound;
            for (NSUInteger index = 0; index < buffer.length; index++) if (bytes[index] == '\n') { newline = index; break; }
            if (newline == NSNotFound) break;
            NSData *line = [buffer subdataWithRange:NSMakeRange(0, newline)];
            [buffer replaceBytesInRange:NSMakeRange(0, newline + 1) withBytes:NULL length:0];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:line options:0 error:nil];
            if ([json[@"id"] integerValue] != 2) continue;
            NSError *parseError = nil;
            TBUsageSnapshot *snapshot = [TBCodexRateLimitParser snapshotFromResponseData:line capturedAt:NSDate.date error:&parseError];
            finish(snapshot, parseError);
            return;
        }
    };
    NSError *launchError = nil;
    if (![task launchAndReturnError:&launchError]) {
        finish(nil, launchError);
        return;
    }
    NSDictionary *initialize = @{@"id": @1, @"method": @"initialize", @"params": @{@"clientInfo": @{@"name": @"tokenbar", @"title": @"Token Balance", @"version": @"1.0.0"}, @"capabilities": @{@"experimentalApi": @YES}}};
    NSDictionary *read = @{@"id": @2, @"method": @"account/rateLimits/read", @"params": NSNull.null};
    NSMutableData *requests = [NSMutableData data];
    for (NSDictionary *request in @[initialize, read]) {
        [requests appendData:[NSJSONSerialization dataWithJSONObject:request options:0 error:nil]];
        [requests appendBytes:"\n" length:1];
    }
    [input.fileHandleForWriting writeData:requests];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSError *timeout = [NSError errorWithDomain:@"TokenBar.AppServer" code:11 userInfo:@{NSLocalizedDescriptionKey: @"连接 ChatGPT 超时，请确认桌面应用已登录。"}];
        finish(nil, timeout);
    });
}
@end

@implementation TBFileUsageProvider
- (instancetype)initWithSourceURL:(NSURL *)sourceURL {
    if ((self = [super init])) {
        _providerID = @"chatgpt";
        _sourceURL = sourceURL;
    }
    return self;
}
- (void)fetchUsageWithCompletion:(void (^)(TBUsageSnapshot *, NSError *))completion {
    NSURL *url = self.sourceURL;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSError *readError = nil;
        NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&readError];
        TBUsageSnapshot *snapshot = data ? [TBChatGPTSnapshotParser snapshotFromData:data error:&readError] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{ completion(snapshot, readError); });
    });
}
@end

@interface TBSnapshotCache ()
@property (nonatomic, strong) NSURL *url;
@end

@implementation TBSnapshotCache
- (instancetype)initWithURL:(NSURL *)url {
    if ((self = [super init])) _url = url;
    return self;
}
- (TBUsageSnapshot *)load:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:self.url options:0 error:error];
    return data ? [TBChatGPTSnapshotParser snapshotFromData:data error:error] : nil;
}
- (BOOL)saveData:(NSData *)data error:(NSError **)error {
    NSURL *directory = [self.url URLByDeletingLastPathComponent];
    if (![NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:error]) return NO;
    return [data writeToURL:self.url options:NSDataWritingAtomic error:error];
}
@end

@implementation TBAlertSettings
- (instancetype)initWithLowPercentThreshold:(NSInteger)lowPercentThreshold
                        resetExpiryThreshold:(NSTimeInterval)resetExpiryThreshold {
    if ((self = [super init])) {
        _lowPercentThreshold = lowPercentThreshold;
        _resetExpiryThreshold = resetExpiryThreshold;
    }
    return self;
}
@end

@implementation TBUsageAlert
- (instancetype)initWithIdentifier:(NSString *)identifier title:(NSString *)title body:(NSString *)body {
    if ((self = [super init])) {
        _identifier = [identifier copy];
        _title = [title copy];
        _body = [body copy];
    }
    return self;
}
@end

@implementation TBAlertEvaluator
+ (NSArray<TBUsageAlert *> *)alertsForSnapshot:(TBUsageSnapshot *)snapshot
                                           now:(NSDate *)now
                                      settings:(TBAlertSettings *)settings {
    NSMutableArray<TBUsageAlert *> *alerts = [NSMutableArray array];
    if (snapshot.percentRemaining && snapshot.percentRemaining.integerValue <= settings.lowPercentThreshold) {
        NSInteger value = snapshot.percentRemaining.integerValue;
        [alerts addObject:[[TBUsageAlert alloc]
            initWithIdentifier:[NSString stringWithFormat:@"weekly-low-%ld", (long)value]
            title:@"ChatGPT Weekly 额度偏低"
            body:[NSString stringWithFormat:@"Weekly 额度仅剩 %ld%%。", (long)value]]];
    }
    for (TBExtraReset *reset in snapshot.extraResets) {
        NSTimeInterval remaining = [reset.expiresAt timeIntervalSinceDate:now];
        if (remaining >= 0 && remaining <= settings.resetExpiryThreshold) {
            [alerts addObject:[[TBUsageAlert alloc]
                initWithIdentifier:[@"reset-expiring-" stringByAppendingString:reset.identifier]
                title:@"额外 Reset 即将过期"
                body:[NSString stringWithFormat:@"1 次额外 Reset 将在 %@后过期。", [TBMenuBarFormatter shortDurationFrom:now to:reset.expiresAt]]]];
        }
    }
    return alerts;
}
@end
