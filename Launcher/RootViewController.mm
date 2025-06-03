
#import <notify.h>

#import "HUDHelper.h"
#import "MainButton.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"

#define HUD_TRANSITION_DURATION 0.25

// Define the notification constants
NSString * const kToggleHUDAfterLaunchNotificationName = @"ch.xxtou.hudapp.notification.toggle-hud";
NSString * const kToggleHUDAfterLaunchNotificationActionKey = @"action";
NSString * const kToggleHUDAfterLaunchNotificationActionToggleOn = @"toggle-on";
NSString * const kToggleHUDAfterLaunchNotificationActionToggleOff = @"toggle-off";

// Static variable to track if we should toggle HUD after launch
static BOOL _shouldToggleHUDAfterLaunch = NO;

@implementation RootViewController {
    MainButton *_mainButton;
    BOOL _isRemoteHUDActive;
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
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
    self.view.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.58f];

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:28/255.0 green:74/255.0 blue:82/255.0 alpha:1.0];
        } else {
            return [UIColor colorWithRed:26/255.0 green:188/255.0 blue:156/255.0 alpha:1.0];
        }
    }];
    [self.view addSubview:self.backgroundView];

    _mainButton = [MainButton buttonWithType:UIButtonTypeSystem];
    [_mainButton setTintColor:[UIColor whiteColor]];
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
    [self.backgroundView addSubview:_mainButton];

    UILayoutGuide *safeArea = self.backgroundView.safeAreaLayoutGuide;
    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_mainButton.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor],
    ]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [self reloadMainButtonState];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void)reloadMainButtonState
{
    _isRemoteHUDActive = [self isHUDEnabled];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf->_mainButton) {
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

    BOOL isCurrentlyEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isCurrentlyEnabled];
    
    [_impactFeedbackGenerator impactOccurred];
    
    self.view.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.userInteractionEnabled = YES;
        [self reloadMainButtonState];
    });
}

+ (void)setShouldToggleHUDAfterLaunch:(BOOL)shouldToggle {
    _shouldToggleHUDAfterLaunch = shouldToggle;
}

@end