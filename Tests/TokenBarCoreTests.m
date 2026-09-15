#import <Foundation/Foundation.h>
#import "TokenBarCore.h"

static int failures = 0;
static int assertions = 0;

static void AssertEqual(NSString *actual, NSString *expected, NSString *name) {
    assertions++;
    if (![actual isEqualToString:expected]) {
        fprintf(stderr, "FAIL %s: expected '%s', got '%s'\n", name.UTF8String, expected.UTF8String, actual.UTF8String);
        failures++;
    }
}

static void AssertTrue(BOOL value, NSString *name) {
    assertions++;
    if (!value) {
        fprintf(stderr, "FAIL %s\n", name.UTF8String);
        failures++;
    }
}

int main(void) {
    @autoreleasepool {
        NSDate *now = [NSDate dateWithTimeIntervalSince1970:1800000000];
        TBUsageSnapshot *normal = [[TBUsageSnapshot alloc] initWithProviderID:@"chatgpt"
            percentRemaining:@72 usesRemaining:@37
            resetsAt:[now dateByAddingTimeInterval:2 * 86400]
            extraResets:@[] capturedAt:now];
        TBMenuBarLabel *normalLabel = [TBMenuBarFormatter labelForSnapshot:normal now:now alertThreshold:86400];
        AssertEqual(normalLabel.text, @"5H —% · W 72% · R×0", @"legacy snapshot shows unknown five-hour and weekly percentage");
        AssertTrue(normalLabel.kind == TBMenuBarLabelKindNormal, @"normal label kind");

        TBExtraReset *reset = [[TBExtraReset alloc] initWithID:@"r1" expiresAt:[now dateByAddingTimeInterval:8 * 3600]];
        TBUsageSnapshot *warning = [[TBUsageSnapshot alloc] initWithProviderID:@"chatgpt"
            percentRemaining:@72 usesRemaining:@37
            resetsAt:[now dateByAddingTimeInterval:2 * 86400]
            extraResets:@[reset] capturedAt:now];
        TBMenuBarLabel *warningLabel = [TBMenuBarFormatter labelForSnapshot:warning now:now alertThreshold:86400];
        AssertEqual(warningLabel.text, @"5H —% · W 72% · R×1 · ⚠ R 8h", @"expiring reset appends warning countdown");
        AssertTrue(warningLabel.kind == TBMenuBarLabelKindWarning, @"warning label kind");

        TBUsageSnapshot *missing = [[TBUsageSnapshot alloc] initWithProviderID:@"chatgpt"
            percentRemaining:@72 usesRemaining:nil
            resetsAt:[now dateByAddingTimeInterval:3600]
            extraResets:@[] capturedAt:now];
        AssertEqual([TBMenuBarFormatter labelForSnapshot:missing now:now alertThreshold:3600].text,
                    @"5H —% · W 72% · R×0", @"missing weekly count shows reset count instead");

        TBUsageSnapshot *stale = [[TBUsageSnapshot alloc] initWithProviderID:@"chatgpt"
            percentRemaining:@72 usesRemaining:@37
            resetsAt:[now dateByAddingTimeInterval:86400]
            extraResets:@[] capturedAt:[now dateByAddingTimeInterval:-7201]];
        TBMenuBarLabel *staleLabel = [TBMenuBarFormatter labelForSnapshot:stale now:now alertThreshold:3600];
        AssertEqual(staleLabel.text, @"5H —% · W 72% · R×0 ↻", @"stale label marker");
        AssertTrue(staleLabel.stale, @"stale flag");

        NSData *canonicalData = [@"{\"provider\":\"chatgpt\",\"weekly\":{\"percentRemaining\":72,\"usesRemaining\":37,\"resetsAt\":\"2027-01-17T10:00:00Z\"},\"extraResets\":[{\"id\":\"r1\",\"expiresAt\":\"2027-01-16T18:00:00Z\"}],\"capturedAt\":\"2027-01-15T10:00:00Z\",\"ignored\":true}" dataUsingEncoding:NSUTF8StringEncoding];
        NSError *parseError = nil;
        TBUsageSnapshot *parsed = [TBChatGPTSnapshotParser snapshotFromData:canonicalData error:&parseError];
        AssertTrue(parsed != nil && parseError == nil, @"canonical JSON parses");
        AssertTrue([parsed.percentRemaining isEqual:@72] && [parsed.usesRemaining isEqual:@37], @"canonical weekly values");
        AssertTrue(parsed.extraResets.count == 1, @"canonical extra reset");

        NSData *snakeData = [@"{\"weekly\":{\"percent_remaining\":65,\"resets_at\":\"2027-01-17T10:00:00Z\"},\"extra_resets\":[],\"captured_at\":\"2027-01-15T10:00:00Z\"}" dataUsingEncoding:NSUTF8StringEncoding];
        TBUsageSnapshot *snake = [TBChatGPTSnapshotParser snapshotFromData:snakeData error:&parseError];
        AssertTrue([snake.percentRemaining isEqual:@65], @"snake case percentage");
        AssertTrue(snake.usesRemaining == nil, @"omitted use count stays nil");

        NSData *badDateData = [@"{\"weekly\":{\"percentRemaining\":72,\"resetsAt\":\"not-a-date\"}}" dataUsingEncoding:NSUTF8StringEncoding];
        TBUsageSnapshot *badDate = [TBChatGPTSnapshotParser snapshotFromData:badDateData error:&parseError];
        AssertTrue(badDate == nil && parseError != nil, @"malformed reset date is rejected");

        TBAlertSettings *alertSettings = [[TBAlertSettings alloc] initWithLowPercentThreshold:10 resetExpiryThreshold:86400];
        TBUsageSnapshot *lowAndExpiring = [[TBUsageSnapshot alloc] initWithProviderID:@"chatgpt"
            percentRemaining:@8 usesRemaining:@3 resetsAt:[now dateByAddingTimeInterval:86400]
            extraResets:@[reset] capturedAt:now];
        NSArray<TBUsageAlert *> *alerts = [TBAlertEvaluator alertsForSnapshot:lowAndExpiring now:now settings:alertSettings];
        AssertTrue(alerts.count == 2, @"low allowance and expiring reset produce two alerts");
        NSSet *alertIDs = [NSSet setWithArray:[alerts valueForKey:@"identifier"]];
        AssertTrue([alertIDs containsObject:@"weekly-low-8"], @"low alert has stable dedupe ID");
        AssertTrue([alertIDs containsObject:@"reset-expiring-r1"], @"reset alert has stable dedupe ID");

        TBUsageSnapshot *healthy = [[TBUsageSnapshot alloc] initWithProviderID:@"chatgpt"
            percentRemaining:@72 usesRemaining:@37 resetsAt:[now dateByAddingTimeInterval:86400]
            extraResets:@[] capturedAt:now];
        AssertTrue([TBAlertEvaluator alertsForSnapshot:healthy now:now settings:alertSettings].count == 0,
                   @"healthy snapshot produces no alerts");

        NSData *appServerData = [@"{\"id\":2,\"result\":{\"rateLimits\":{\"limitId\":\"codex\",\"primary\":{\"usedPercent\":35,\"windowDurationMins\":10080,\"resetsAt\":1800500000},\"planType\":\"plus\"},\"rateLimitResetCredits\":{\"availableCount\":2,\"credits\":[{\"id\":\"credit-1\",\"status\":\"available\",\"expiresAt\":1800100000},{\"id\":\"credit-2\",\"status\":\"available\",\"expiresAt\":1800200000}]}}}" dataUsingEncoding:NSUTF8StringEncoding];
        TBUsageSnapshot *automatic = [TBCodexRateLimitParser snapshotFromResponseData:appServerData capturedAt:now error:&parseError];
        AssertTrue([automatic.percentRemaining isEqual:@65], @"app-server used percentage converts to remaining");
        AssertTrue(automatic.usesRemaining == nil, @"app-server does not invent remaining uses");
        AssertTrue(automatic.extraResets.count == 2, @"app-server reads available reset details");
        AssertTrue([automatic.resetsAt isEqualToDate:[NSDate dateWithTimeIntervalSince1970:1800500000]], @"app-server reads weekly reset date");
        AssertEqual([TBMenuBarFormatter labelForSnapshot:automatic now:now alertThreshold:3600].text,
                    @"5H —% · W 65% · R×2", @"automatic label displays remaining reset count");

        NSDictionary *shortWindow = @{@"usedPercent": @18, @"windowDurationMins": @300, @"resetsAt": @1800007200};
        NSDictionary *weekWindow = @{@"usedPercent": @35, @"windowDurationMins": @10080, @"resetsAt": @1800500000};
        // Exercise both slot orders and both response envelopes. The Codex bucket
        // must win over the legacy snapshot and unrelated model-specific buckets.
        for (NSNumber *swapped in @[@NO, @YES]) {
            for (NSNumber *bucketed in @[@NO, @YES]) {
                NSDictionary *windows = @{@"primary": swapped.boolValue ? weekWindow : shortWindow,
                                          @"secondary": swapped.boolValue ? shortWindow : weekWindow};
                NSMutableDictionary *result = [@{@"rateLimits": windows,
                    @"rateLimitResetCredits": @{@"availableCount": @2, @"credits": @[]}} mutableCopy];
                if (bucketed.boolValue) {
                    result[@"rateLimits"] = @{@"primary": @{@"windowDurationMins": @300, @"usedPercent": @99}};
                    result[@"rateLimitsByLimitId"] = @{@"codex": windows, @"other": result[@"rateLimits"]};
                }
                NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"result": result} options:0 error:nil];
                TBUsageSnapshot *both = [TBCodexRateLimitParser snapshotFromResponseData:data capturedAt:now error:nil];
                AssertTrue([both.fiveHourPercentRemaining isEqual:@82] && [both.percentRemaining isEqual:@65], @"windows are selected by duration in both envelopes");
                AssertTrue([both.fiveHourResetsAt isEqualToDate:[NSDate dateWithTimeIntervalSince1970:1800007200]], @"five-hour reset is independent");
                AssertTrue([both.resetsAt isEqualToDate:automatic.resetsAt], @"weekly reset is preserved");
                AssertEqual([TBMenuBarFormatter labelForSnapshot:both now:now alertThreshold:3600].text, @"5H 82% · W 65% · R×2", @"dual-window label keeps banked count without expiry details");
            }
        }
        NSArray *partialWindows = @[
            @{@"primary": shortWindow},
            @{@"secondary": weekWindow},
            @{@"primary": NSNull.null, @"secondary": NSNull.null},
            @{@"primary": @{@"windowDurationMins": @60, @"usedPercent": @20}},
            @{@"primary": @{@"windowDurationMins": NSNull.null, @"usedPercent": @20}},
            @{@"primary": @{@"windowDurationMins": @300, @"usedPercent": NSNull.null, @"resetsAt": NSNull.null}}
        ];
        for (NSUInteger index = 0; index < partialWindows.count; index++) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"result": @{@"rateLimits": partialWindows[index]}} options:0 error:nil];
            TBUsageSnapshot *partial = [TBCodexRateLimitParser snapshotFromResponseData:data capturedAt:now error:nil];
            AssertTrue(partial != nil, @"partial or null window does not crash");
            AssertTrue(index == 1 ? [partial.percentRemaining isEqual:@65] : partial.percentRemaining == nil, @"short or unknown window is never reported as weekly");
            AssertTrue(index == 0 ? [partial.fiveHourPercentRemaining isEqual:@82] : partial.fiveHourPercentRemaining == nil, @"missing five-hour data remains unknown");
        }
        for (NSNumber *used in @[@(-20), @120, @18.5]) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"result": @{@"rateLimits": @{@"primary": @{@"windowDurationMins": @300, @"usedPercent": used}}}} options:0 error:nil];
            TBUsageSnapshot *bounded = [TBCodexRateLimitParser snapshotFromResponseData:data capturedAt:now error:nil];
            NSNumber *expected = used.doubleValue < 0 ? @100 : (used.doubleValue > 100 ? @0 : @81.5);
            AssertTrue([bounded.fiveHourPercentRemaining isEqual:expected], @"remaining percent clamps bounds and preserves fractions");
        }

        TBWatcherPolicy *policy = [TBWatcherPolicy new];
        AssertTrue([policy initialActionWithChatGPTRunning:YES tokenBarRunning:NO] == TBWatcherActionLaunchTokenBar,
                   @"watcher launches TokenBar when ChatGPT is already running");
        [policy tokenBarDidTerminateWhileChatGPTRunning:YES];
        AssertTrue(policy.suppressedUntilNextChatGPTLaunch, @"manual TokenBar quit suppresses relaunch in current ChatGPT session");
        AssertTrue([policy chatGPTDidLaunchWithTokenBarRunning:NO] == TBWatcherActionNone,
                   @"duplicate launch event respects manual quit suppression");
        AssertTrue([policy chatGPTDidTerminateWithTokenBarRunning:NO] == TBWatcherActionNone,
                   @"ChatGPT termination clears suppression without redundant termination");
        AssertTrue([policy chatGPTDidLaunchWithTokenBarRunning:NO] == TBWatcherActionLaunchTokenBar,
                   @"next ChatGPT session launches TokenBar again");
        AssertTrue([policy chatGPTDidTerminateWithTokenBarRunning:YES] == TBWatcherActionTerminateTokenBar,
                   @"ChatGPT termination closes running TokenBar");

        if (failures == 0) printf("PASS TokenBarCoreTests (%d assertions)\n", assertions);
        return failures == 0 ? 0 : 1;
    }
}
