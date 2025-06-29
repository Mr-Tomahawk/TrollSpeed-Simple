//
//  RootViewController.mm
//  RedSquareHUD // Updated project name
//
//  Created by Lessica on 2024/1/24. // Keep original author for credit
//

#import <notify.h>

#import "HUDHelper.h"
#import "MainButton.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"

#define HUD_TRANSITION_DURATION 0.25

// static BOOL _gShouldToggleHUDAfterLaunch = NO; // Removed

@implementation RootViewController {
    MainButton *_mainButton;
    BOOL _isRemoteHUDActive; // Kept for now, usage might simplify after AppDelegate changes
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
}

// + (void)setShouldToggleHUDAfterLaunch:(BOOL)flag
// {
//     _gShouldToggleHUDAfterLaunch = flag;
// }

// + (BOOL)shouldToggleHUDAfterLaunch
// {
//     return _gShouldToggleHUDAfterLaunch;
// }

- (BOOL)isHUDEnabled
{
    return IsHUDEnabled();
}

- (void)setHUDEnabled:(BOOL)enabled
{
    SetHUDEnabled(enabled);
}

// - (void)registerNotifications
// {
//     // URL scheme/shortcut toggling removed
//     // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleHUDNotificationReceived:) name:kToggleHUDAfterLaunchNotificationName object:nil];
// }

- (void)loadView
{
    CGRect bounds = UIScreen.mainScreen.bounds;

    self.view = [[UIView alloc] initWithFrame:bounds];
    // Set a simple background color
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // Keep main button only
    _mainButton = [MainButton buttonWithType:UIButtonTypeSystem];
    [_mainButton setTintColor:[UIColor labelColor]]; // Use dynamic color
    [_mainButton addTarget:self action:@selector(tapMainButton:) forControlEvents:UIControlEventTouchUpInside];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration tintedButtonConfiguration];
        [config setTitleTextAttributesTransformer:^NSDictionary <NSAttributedStringKey, id> * _Nonnull(NSDictionary <NSAttributedStringKey, id> * _Nonnull textAttributes) {
            NSMutableDictionary *newAttributes = [textAttributes mutableCopy];
            [newAttributes setObject:[UIFont boldSystemFontOfSize:32.0] forKey:NSFontAttributeName];
            return newAttributes;
        }];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_mainButton setConfiguration:config];
    }
    else
    {
        [_mainButton.titleLabel setFont:[UIFont boldSystemFontOfSize:32.0]];
    }
    [self.view addSubview:_mainButton]; // Add to self.view directly

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide; // Use self.view safe area
    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_mainButton.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor], // Center in safe area
    ]];

    [self reloadMainButtonState];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    // [self registerNotifications]; // Removed
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // [self toggleHUDAfterLaunch]; // Removed URL scheme/shortcut handling
}

// --- URL Scheme/Shortcut Handling Removed ---
// - (void)toggleHUDNotificationReceived:(NSNotification *)notification {
//     // ...
// }

// - (void)toggleHUDAfterLaunch {
//     // ...
// }

// - (void)toggleOnHUDAfterLaunch {
//     // ...
// }

// - (void)toggleOffHUDAfterLaunch {
//     // ...
// }
// --- End URL Scheme/Shortcut Handling ---


// Simplified reloadMainButtonState
- (void)reloadMainButtonState
{
    _isRemoteHUDActive = [self isHUDEnabled];
    // Only update the button title
     __weak typeof(self) weakSelf = self;
    [UIView transitionWithView:_mainButton duration:HUD_TRANSITION_DURATION options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
         __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf->_mainButton setTitle:(strongSelf->_isRemoteHUDActive ? NSLocalizedString(@"Exit HUD", nil) : NSLocalizedString(@"Open HUD", nil)) forState:UIControlStateNormal];
    } completion:nil];
}


- (void)tapMainButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapMainButton:%{public}@]", sender);

    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];
    isNowEnabled = !isNowEnabled; // Update state after toggling

    // Keep feedback and state update logic, simplify UI interaction part
    if (isNowEnabled)
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        [_impactFeedbackGenerator prepare];
        int anyToken;
        __weak typeof(self) weakSelf = self;
        notify_register_dispatch(NOTIFY_LAUNCHED_HUD, &anyToken, dispatch_get_main_queue(), ^(int token) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            notify_cancel(token);
            [strongSelf->_impactFeedbackGenerator impactOccurred];
            dispatch_semaphore_signal(semaphore);
        });

        // Disable button temporarily? Or rely on async update?
        // sender.enabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            intptr_t timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut) {
                    log_error(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                }
                [self reloadMainButtonState];
                // sender.enabled = YES;
            });
        });
    }
    else
    {
        // sender.enabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            // sender.enabled = YES;
        });
    }
}

// Removed unused methods

@end