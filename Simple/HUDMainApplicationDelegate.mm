//
//  HUDMainApplicationDelegate.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <objc/runtime.h>

#import "HUDMainApplicationDelegate.h"
#import "HUDMainWindow.h"
#import "HUDRootViewController.h"

#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"
#import <notify.h>

@implementation HUDMainApplicationDelegate {
    int _visibilityToggleToken;
    HUDRootViewController *_rootViewController;
    SBSAccessibilityWindowHostingController *_windowHostingController;
}

- (instancetype)init
{
    if (self = [super init])
    {
        log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate init]");
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions
{
    log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);

    _rootViewController = [[HUDRootViewController alloc] init];

    self.window = [[HUDMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_rootViewController];
    
    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];

    _windowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init];
    unsigned int _contextId = [self.window _contextId];
    double windowLevel = [self.window windowLevel];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // [_windowHostingController registerWindowWithContextID:_contextId atLevel:windowLevel];
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:_windowHostingController];
    [invocation setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
    [invocation setArgument:&_contextId atIndex:2];
    [invocation setArgument:&windowLevel atIndex:3];
    [invocation invoke];
#pragma clang diagnostic pop

    // Register for HUD visibility toggle notification
    __weak typeof(self) weakSelf = self;
    notify_register_dispatch([kToggleHUDVisibilityNotificationName UTF8String], &_visibilityToggleToken, dispatch_get_main_queue(), ^(int token) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf handleVisibilityToggleNotification];
        }
    });

    return YES;
}

- (void)handleVisibilityToggleNotification {
    log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate handleVisibilityToggleNotification]");
    self.window.hidden = !self.window.hidden;
    log_info(OS_LOG_DEFAULT, "HUD window visibility toggled to: %{public}s", self.window.hidden ? "Hidden" : "Visible");
}

- (void)dealloc {
    if (_visibilityToggleToken) {
        notify_cancel(_visibilityToggleToken);
    }
    log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate dealloc]");
}

@end