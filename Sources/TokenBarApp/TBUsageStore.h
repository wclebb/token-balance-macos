#import <Foundation/Foundation.h>
#import "TokenBarCore.h"

NS_ASSUME_NONNULL_BEGIN

@class TBUsageStore;

@protocol TBUsageStoreDelegate <NSObject>
- (void)usageStoreDidChange:(TBUsageStore *)store;
@end

@interface TBUsageStore : NSObject
@property (nonatomic, weak, nullable) id<TBUsageStoreDelegate> delegate;
@property (nonatomic, strong, readonly, nullable) TBUsageSnapshot *snapshot;
@property (nonatomic, strong, readonly, nullable) NSError *lastError;
@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;
@property (nonatomic, readonly) NSTimeInterval refreshInterval;
- (instancetype)initWithProvider:(id<TBUsageProvider>)provider;
- (void)start;
- (void)refresh;
@end

NS_ASSUME_NONNULL_END
