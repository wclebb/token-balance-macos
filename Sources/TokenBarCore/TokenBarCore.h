#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TBMenuBarLabelKind) {
    TBMenuBarLabelKindNormal,
    TBMenuBarLabelKindWarning,
    TBMenuBarLabelKindError
};

typedef NS_ENUM(NSInteger, TBWatcherAction) {
    TBWatcherActionNone,
    TBWatcherActionLaunchTokenBar,
    TBWatcherActionTerminateTokenBar
};

@interface TBWatcherPolicy : NSObject
@property (nonatomic, readonly, getter=isSuppressedUntilNextChatGPTLaunch) BOOL suppressedUntilNextChatGPTLaunch;
- (TBWatcherAction)initialActionWithChatGPTRunning:(BOOL)chatGPTRunning tokenBarRunning:(BOOL)tokenBarRunning;
- (TBWatcherAction)chatGPTDidLaunchWithTokenBarRunning:(BOOL)tokenBarRunning;
- (TBWatcherAction)chatGPTDidTerminateWithTokenBarRunning:(BOOL)tokenBarRunning;
- (void)tokenBarDidTerminateWhileChatGPTRunning:(BOOL)chatGPTRunning;
@end

@interface TBExtraReset : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSDate *expiresAt;
- (instancetype)initWithID:(NSString *)identifier expiresAt:(NSDate *)expiresAt;
@end

@interface TBUsageSnapshot : NSObject
@property (nonatomic, copy, readonly) NSString *providerID;
// Existing unprefixed fields describe the weekly window.
@property (nonatomic, strong, readonly, nullable) NSNumber *fiveHourPercentRemaining;
@property (nonatomic, strong, readonly, nullable) NSDate *fiveHourResetsAt;
@property (nonatomic, strong, readonly, nullable) NSNumber *percentRemaining;
@property (nonatomic, strong, readonly, nullable) NSNumber *usesRemaining;
@property (nonatomic, strong, readonly, nullable) NSDate *resetsAt;
@property (nonatomic, copy, readonly) NSArray<TBExtraReset *> *extraResets;
@property (nonatomic, readonly) NSInteger extraResetCount;
@property (nonatomic, strong, readonly) NSDate *capturedAt;
- (instancetype)initWithProviderID:(NSString *)providerID
                  percentRemaining:(nullable NSNumber *)percentRemaining
                     usesRemaining:(nullable NSNumber *)usesRemaining
                          resetsAt:(nullable NSDate *)resetsAt
                       extraResets:(NSArray<TBExtraReset *> *)extraResets
                        capturedAt:(NSDate *)capturedAt;
- (instancetype)initWithProviderID:(NSString *)providerID
                  percentRemaining:(nullable NSNumber *)percentRemaining
                     usesRemaining:(nullable NSNumber *)usesRemaining
                          resetsAt:(nullable NSDate *)resetsAt
                       extraResets:(NSArray<TBExtraReset *> *)extraResets
                   extraResetCount:(NSInteger)extraResetCount
                        capturedAt:(NSDate *)capturedAt;
- (instancetype)initWithProviderID:(NSString *)providerID
                  percentRemaining:(nullable NSNumber *)percentRemaining
                     usesRemaining:(nullable NSNumber *)usesRemaining
                          resetsAt:(nullable NSDate *)resetsAt
          fiveHourPercentRemaining:(nullable NSNumber *)fiveHourPercentRemaining
                  fiveHourResetsAt:(nullable NSDate *)fiveHourResetsAt
                       extraResets:(NSArray<TBExtraReset *> *)extraResets
                   extraResetCount:(NSInteger)extraResetCount
                        capturedAt:(NSDate *)capturedAt;

@end

@interface TBMenuBarLabel : NSObject
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, readonly) TBMenuBarLabelKind kind;
@property (nonatomic, readonly, getter=isStale) BOOL stale;
- (instancetype)initWithText:(NSString *)text kind:(TBMenuBarLabelKind)kind stale:(BOOL)stale;
@end

@interface TBMenuBarFormatter : NSObject
+ (TBMenuBarLabel *)labelForSnapshot:(TBUsageSnapshot *)snapshot
                                 now:(NSDate *)now
                      alertThreshold:(NSTimeInterval)alertThreshold;
+ (NSString *)shortDurationFrom:(NSDate *)now to:(NSDate *)future;
@end

@protocol TBUsageProvider <NSObject>
@property (nonatomic, copy, readonly) NSString *providerID;
- (void)fetchUsageWithCompletion:(void (^)(TBUsageSnapshot * _Nullable snapshot, NSError * _Nullable error))completion;
@end

@interface TBChatGPTSnapshotParser : NSObject
+ (nullable TBUsageSnapshot *)snapshotFromData:(NSData *)data error:(NSError **)error;
@end

@interface TBCodexRateLimitParser : NSObject
+ (nullable TBUsageSnapshot *)snapshotFromResponseData:(NSData *)data
                                             capturedAt:(NSDate *)capturedAt
                                                  error:(NSError **)error;
@end

@interface TBCodexAppServerProvider : NSObject <TBUsageProvider>
@property (nonatomic, copy, readonly) NSString *providerID;
@end

@interface TBFileUsageProvider : NSObject <TBUsageProvider>
@property (nonatomic, copy, readonly) NSString *providerID;
@property (nonatomic, strong) NSURL *sourceURL;
- (instancetype)initWithSourceURL:(NSURL *)sourceURL;
@end

@interface TBSnapshotCache : NSObject
- (instancetype)initWithURL:(NSURL *)url;
- (nullable TBUsageSnapshot *)load:(NSError **)error;
- (BOOL)saveData:(NSData *)data error:(NSError **)error;
@end

@interface TBAlertSettings : NSObject
@property (nonatomic, readonly) NSInteger lowPercentThreshold;
@property (nonatomic, readonly) NSTimeInterval resetExpiryThreshold;
- (instancetype)initWithLowPercentThreshold:(NSInteger)lowPercentThreshold
                        resetExpiryThreshold:(NSTimeInterval)resetExpiryThreshold;
@end

@interface TBUsageAlert : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *body;
- (instancetype)initWithIdentifier:(NSString *)identifier title:(NSString *)title body:(NSString *)body;
@end

@interface TBAlertEvaluator : NSObject
+ (NSArray<TBUsageAlert *> *)alertsForSnapshot:(TBUsageSnapshot *)snapshot
                                           now:(NSDate *)now
                                      settings:(TBAlertSettings *)settings;
@end

NS_ASSUME_NONNULL_END
