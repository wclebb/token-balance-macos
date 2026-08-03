#import "TBAppDelegate.h"
#import "TBWatcherInstaller.h"
#import <UserNotifications/UserNotifications.h>

@interface TBAppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *statusMenu;
@property (nonatomic, strong) TBUsageStore *store;
@end

@implementation TBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [TBWatcherInstaller installForApplicationBundle:NSBundle.mainBundle];
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"—% · W— · —";
    self.statusItem.button.contentTintColor = nil;
    self.statusItem.button.toolTip = @"Token 余量 — ChatGPT 订阅额度";

    self.statusMenu = [NSMenu new];
    self.statusMenu.delegate = self;
    self.statusItem.menu = self.statusMenu;

    self.store = [[TBUsageStore alloc] initWithProvider:[TBCodexAppServerProvider new]];
    self.store.delegate = self;
    [self requestNotificationAuthorization];
    [self rebuildMenu];
    [self.store start];
}

- (NSMenuItem *)itemWithTitle:(NSString *)title action:(SEL)action {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
    item.target = action ? self : nil;
    return item;
}

- (NSMenu *)submenuWithTitle:(NSString *)title parent:(NSMenu *)parent {
    NSMenuItem *item = [self itemWithTitle:title action:nil];
    NSMenu *submenu = [[NSMenu alloc] initWithTitle:title];
    item.submenu = submenu;
    [parent addItem:item];
    return submenu;
}

- (void)addChoice:(NSString *)title value:(NSInteger)value selected:(BOOL)selected action:(SEL)action toMenu:(NSMenu *)menu {
    NSMenuItem *item = [self itemWithTitle:title action:action];
    item.tag = value;
    item.state = selected ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:item];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == self.statusMenu) [self rebuildMenu];
}

- (void)rebuildMenu {
    [self.statusMenu removeAllItems];
    TBUsageSnapshot *snapshot = self.store.snapshot;
    NSInteger alertHours = [NSUserDefaults.standardUserDefaults integerForKey:@"resetAlertHours"] ?: 24;
    NSString *usageText = @"尚未载入额度";
    if (snapshot) usageText = [TBMenuBarFormatter labelForSnapshot:snapshot now:NSDate.date alertThreshold:alertHours * 3600].text;

    NSMenuItem *provider = [self itemWithTitle:@"ChatGPT" action:nil];
    provider.enabled = NO;
    [self.statusMenu addItem:provider];
    NSMenuItem *usage = [self itemWithTitle:usageText action:nil];
    usage.enabled = NO;
    [self.statusMenu addItem:usage];
    [self.statusMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *refresh = [self itemWithTitle:self.store.isRefreshing ? @"正在刷新…" : @"立即刷新" action:@selector(refresh:)];
    refresh.enabled = !self.store.isRefreshing;
    [self.statusMenu addItem:refresh];

    NSMenu *sourceMenu = [self submenuWithTitle:@"数据源" parent:self.statusMenu];
    NSMenuItem *sourceState = [self itemWithTitle:self.store.lastError ? @"状态：连接失败" : (snapshot ? @"状态：已自动连接" : @"状态：正在连接") action:nil];
    sourceState.enabled = NO;
    [sourceMenu addItem:sourceState];
    [sourceMenu addItem:[self itemWithTitle:@"重新连接" action:@selector(refresh:)]];
    NSMenuItem *sourceHelp = [self itemWithTitle:@"自动复用 ChatGPT/Codex 登录状态" action:nil];
    sourceHelp.enabled = NO;
    sourceHelp.toolTip = @"Token 余量调用本机 ChatGPT 自带的 app-server，不读取或保存登录令牌。";
    [sourceMenu addItem:sourceHelp];
    if (self.store.lastError) {
        NSMenuItem *error = [self itemWithTitle:self.store.lastError.localizedDescription action:nil];
        error.enabled = NO;
        [sourceMenu addItem:error];
    }

    BOOL notificationsEnabled = [NSUserDefaults.standardUserDefaults objectForKey:@"notificationsEnabled"] ? [NSUserDefaults.standardUserDefaults boolForKey:@"notificationsEnabled"] : YES;
    NSMenu *notificationMenu = [self submenuWithTitle:@"通知" parent:self.statusMenu];
    [self addChoice:@"开启" value:1 selected:notificationsEnabled action:@selector(chooseNotification:) toMenu:notificationMenu];
    [self addChoice:@"关闭" value:0 selected:!notificationsEnabled action:@selector(chooseNotification:) toMenu:notificationMenu];

    NSMenu *resetMenu = [self submenuWithTitle:@"Reset 到期提醒" parent:self.statusMenu];
    for (NSNumber *hours in @[@8, @24, @48]) {
        [self addChoice:[NSString stringWithFormat:@"到期前 %@ 小时", hours] value:hours.integerValue selected:alertHours == hours.integerValue action:@selector(chooseResetHours:) toMenu:resetMenu];
    }

    [self.statusMenu addItem:NSMenuItem.separatorItem];
    [self.statusMenu addItem:[self itemWithTitle:@"退出" action:@selector(quit:)]];
}

- (void)refresh:(id)sender {
    [self.store refresh];
    [self rebuildMenu];
}

- (void)chooseNotification:(NSMenuItem *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.tag == 1 forKey:@"notificationsEnabled"];
    [self rebuildMenu];
}

- (void)chooseResetHours:(NSMenuItem *)sender {
    [NSUserDefaults.standardUserDefaults setInteger:sender.tag forKey:@"resetAlertHours"];
    [self usageStoreDidChange:self.store];
}

- (void)usageStoreDidChange:(TBUsageStore *)store {
    TBUsageSnapshot *snapshot = store.snapshot;
    if (!snapshot) {
        self.statusItem.button.title = store.isRefreshing ? @"同步中…" : @"—% · W— · —";
        self.statusItem.button.contentTintColor = nil;
        [self rebuildMenu];
        return;
    }
    NSInteger alertHours = [NSUserDefaults.standardUserDefaults integerForKey:@"resetAlertHours"] ?: 24;
    TBMenuBarLabel *label = [TBMenuBarFormatter labelForSnapshot:snapshot now:NSDate.date alertThreshold:alertHours * 3600];
    self.statusItem.button.title = label.text;
    self.statusItem.button.contentTintColor = nil;
    [self rebuildMenu];
    [self deliverAlertsForSnapshot:snapshot threshold:alertHours * 3600];
}

- (void)requestNotificationAuthorization {
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound) completionHandler:^(__unused BOOL granted, __unused NSError *error) {}];
}

- (void)deliverAlertsForSnapshot:(TBUsageSnapshot *)snapshot threshold:(NSTimeInterval)threshold {
    BOOL enabled = [NSUserDefaults.standardUserDefaults objectForKey:@"notificationsEnabled"] ? [NSUserDefaults.standardUserDefaults boolForKey:@"notificationsEnabled"] : YES;
    if (!enabled) return;
    NSInteger low = [NSUserDefaults.standardUserDefaults integerForKey:@"lowPercentThreshold"] ?: 10;
    TBAlertSettings *settings = [[TBAlertSettings alloc] initWithLowPercentThreshold:low resetExpiryThreshold:threshold];
    NSMutableSet *delivered = [NSMutableSet setWithArray:[NSUserDefaults.standardUserDefaults stringArrayForKey:@"deliveredAlertIDs"] ?: @[]];
    for (TBUsageAlert *event in [TBAlertEvaluator alertsForSnapshot:snapshot now:NSDate.date settings:settings]) {
        if ([delivered containsObject:event.identifier]) continue;
        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
        content.title = event.title;
        content.body = event.body;
        content.sound = UNNotificationSound.defaultSound;
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:event.identifier content:content trigger:nil];
        [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:nil];
        [delivered addObject:event.identifier];
    }
    [NSUserDefaults.standardUserDefaults setObject:delivered.allObjects forKey:@"deliveredAlertIDs"];
}

- (void)quit:(id)sender { [NSApp terminate:nil]; }
@end
