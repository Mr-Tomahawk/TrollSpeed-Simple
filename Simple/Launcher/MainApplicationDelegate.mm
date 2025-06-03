//
//  MainApplicationDelegate.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import "MainApplicationDelegate.h"
#import "MainApplication.h" // This will be the new Simple/MainApplication.h
#import "RootViewController.h" // This is Simple/RootViewController.h
#import "HUDHelper.h" // This is Simple/HUDHelper.h

// Logging macros (e.g., log_debug) are expected to be defined in RedSquareHUD-Prefix.pch

@implementation MainApplicationDelegate {
    RootViewController *_rootViewController;
}

- (instancetype)init {
    if (self = [super init]) {
        log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate init]");
    }
    return self;
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    if ([url.scheme isEqualToString:@"trollspeed"]) { // Using "trollspeed" scheme from Speed project
        if ([url.host isEqualToString:@"toggle"]) {
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:nil];
            return YES;
        } else if ([url.host isEqualToString:@"on"]) {
            // kToggleHUDAfterLaunchNotificationActionToggleOn should be available via RootViewController.h
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:kToggleHUDAfterLaunchNotificationActionToggleOn];
            return YES;
        } else if ([url.host isEqualToString:@"off"]) {
            // kToggleHUDAfterLaunchNotificationActionToggleOff should be via RootViewController.h
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:kToggleHUDAfterLaunchNotificationActionToggleOff];
            return YES;
        }
    }
    return NO;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler
{
    BOOL handled = NO;
    if ([shortcutItem.type isEqualToString:@"ch.xxtou.shortcut.toggle-hud"]) // Using Speed's shortcut type
    {
        [self setupAndNotifyToggleHUDAfterLaunchWithAction:nil];
        handled = YES;
    }
    if (completionHandler) {
        completionHandler(handled);
    }
}

- (void)setupAndNotifyToggleHUDAfterLaunchWithAction:(NSString *)action
{
    // This static method [RootViewController setShouldToggleHUDAfterLaunch:YES]
    // will need to exist in Simple/RootViewController.
    // If not, it will cause a build error, and we will add it.
    [RootViewController setShouldToggleHUDAfterLaunch:YES];
    
    // kToggleHUDAfterLaunchNotificationName and kToggleHUDAfterLaunchNotificationActionKey
    // should be available via RootViewController.h
    if (action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kToggleHUDAfterLaunchNotificationName object:nil userInfo:@{
            kToggleHUDAfterLaunchNotificationActionKey: action,
        }];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kToggleHUDAfterLaunchNotificationName object:nil];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions {
    log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@", application, launchOptions);

    _rootViewController = [[RootViewController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_rootViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate applicationDidBecomeActive:%{public}@", application);

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && strongSelf->_rootViewController) {
            [strongSelf->_rootViewController reloadMainButtonState];
        }
    });
}

@end
