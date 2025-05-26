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

static BOOL _shouldToggleHUDAfterLaunch = NO; // Added static variable

@implementation RootViewController {
    MainButton *_mainButton; // Declare _mainButton ivar
    BOOL _isRemoteHUDActive;
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
    // UIView *_backgroundView; // This is a property now
}

// Correct placement for static method implementations
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag {
    _shouldToggleHUDAfterLaunch = flag;
}

+ (BOOL)shouldToggleHUDAfterLaunch {
    return _shouldToggleHUDAfterLaunch;
}

- (BOOL)isHUDEnabled
{
    return IsHUDEnabled();
}

- (void)setHUDEnabled:(BOOL)enabled
{
    SetHUDEnabled(enabled);
}

- (void)loadView
{
    CGRect bounds = UIScreen.mainScreen.bounds;

    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor colorWithRed:0.0f / 255.0f green:0.0f / 255.0f blue:0.0f / 255.0f alpha:.580f / 1.0f]; // From Speed

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) { // From Speed
        if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:28/255.0 green:74/255.0 blue:82/255.0 alpha:1.0];
        } else {
            return [UIColor colorWithRed:26/255.0 green:188/255.0 blue:156/255.0 alpha:1.0];
        }
    }];
    [self.view addSubview:self.backgroundView];

    _mainButton = [MainButton buttonWithType:UIButtonTypeSystem];
    [_mainButton setTintColor:[UIColor whiteColor]]; // From Speed (buttons are on dark background)
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
    [self.backgroundView addSubview:_mainButton]; // Add to backgroundView

    UILayoutGuide *safeArea = self.backgroundView.safeAreaLayoutGuide; // Use backgroundView safe area
    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_mainButton.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor],
    ]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Setup 3-finger tap gesture for HUD visibility toggle
    UITapGestureRecognizer *toggleHudGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHudVisibilityToggleGesture:)];
    toggleHudGesture.numberOfTouchesRequired = 3;
    toggleHudGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:toggleHudGesture];

    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [self reloadMainButtonState];
    [self registerNotifications];
}

// Method to handle the 3-finger tap gesture
- (void)handleHudVisibilityToggleGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        NSLog(@"[Simple] 3-finger tap detected, posting notification to toggle HUD visibility.");
        notify_post([kToggleHUDVisibilityNotificationName UTF8String]);
    }
}

- (void)registerNotifications
{
    int token;
    // NOTIFY_RELOAD_APP is defined in RedSquareHUD-Prefix.pch
    notify_register_dispatch(NOTIFY_RELOAD_APP, &token, dispatch_get_main_queue(), ^(int t) {
        // For Simple, just reload the button state, as there are no extensive user defaults like in Speed
        [self reloadMainButtonState];
    });

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleHUDNotificationReceived:) name:kToggleHUDAfterLaunchNotificationName object:nil];
}

- (void)toggleHUDNotificationReceived:(NSNotification *)notification {
    // Simplified for Simple: always toggle the current state
    // NSString *toggleAction = notification.userInfo[kToggleHUDAfterLaunchNotificationActionKey];
    log_debug(OS_LOG_DEFAULT, "- [RootViewController toggleHUDNotificationReceived:%{public}@ userInfo:%{public}@", notification.name, notification.userInfo);
    
    // Directly toggle the HUD state, similar to tapMainButton but without sender
    BOOL isCurrentlyEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isCurrentlyEnabled];
    
    // Optionally, trigger feedback and UI update if needed, or rely on tapMainButton's logic if it's called by this.
    // For now, just reload state, tapMainButton handles the complex feedback/timeout.
    [self reloadMainButtonState]; 
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // notify_cancel should be handled for the specific token if stored, 
    // but for NOTIFY_RELOAD_APP, the token from notify_register_dispatch is local to registerNotifications.
    // If we stored the token as an ivar, we would cancel it here.
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // No automatic toggle on appear for Simple
}


// Simplified reloadMainButtonState
- (void)reloadMainButtonState
{
    _isRemoteHUDActive = [self isHUDEnabled];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf->_mainButton) { // Added check for _mainButton
            return;
        }
        [UIView transitionWithView:strongSelf->_mainButton duration:HUD_TRANSITION_DURATION options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            __strong typeof(weakSelf) animationStrongSelf = weakSelf;
            if (!animationStrongSelf || !animationStrongSelf->_mainButton) return;
            [animationStrongSelf->_mainButton setTitle:(animationStrongSelf->_isRemoteHUDActive ? NSLocalizedString(@"Exit HUD", nil) : NSLocalizedString(@"Open HUD", nil)) forState:UIControlStateNormal];
        } completion:nil];
    });
}


- (void)tapMainButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapMainButton:%{public}@]", sender);

    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];
    // isNowEnabled = !isNowEnabled; // This was potentially confusing, _isRemoteHUDActive is updated by reloadMainButtonState

    // Get the new state *after* toggling for the UI logic
    BOOL newTargetState = !isNowEnabled; 

    if (newTargetState) // If HUD is being turned ON
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [_impactFeedbackGenerator prepare];
        int anyToken;
        __weak typeof(self) weakSelf = self;
        notify_register_dispatch(NOTIFY_LAUNCHED_HUD, &anyToken, dispatch_get_main_queue(), ^(int token) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { notify_cancel(token); return; }
            notify_cancel(token);
            [strongSelf->_impactFeedbackGenerator impactOccurred];
            dispatch_semaphore_signal(semaphore);
        });

        self.view.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            intptr_t timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut) {
                    log_error(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                }
                self.view.userInteractionEnabled = YES;
                [self reloadMainButtonState];
            });
        });
    }
    else // If HUD is being turned OFF
    {
        self.view.userInteractionEnabled = NO;
        // No NOTIFY_EXITED_HUD in Simple's HUD process, so just use a delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.view.userInteractionEnabled = YES;
            [self reloadMainButtonState];
        });
    }
}

@end