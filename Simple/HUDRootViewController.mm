//
//  HUDRootViewController.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <notify.h>
// Removed network imports
#import <objc/runtime.h>
// #import <mach/vm_param.h> // Unused
// #import <Foundation/Foundation.h> // Included via PCH

// #import "HUDPresetPosition.h" // Removed
#import "HUDRootViewController.h"
// #import "HUDBackdropLabel.h" // Removed as speed label was removed
// #import "RedSquareHUD-Swift.h" // Removed ScreenshotInvisibleContainer

#pragma mark -

// #import "FBSOrientationUpdate.h" // Removed orientation logic
// #import "FBSOrientationObserver.h" // Removed orientation logic
// #import "UIApplication+Private.h" // Removed as static functions using it were removed
// #import "LSApplicationProxy.h" // Removed notification logic
// #import "LSApplicationWorkspace.h" // Removed notification logic
// #import "SpringBoardServices.h" // Removed as static functions using it were removed

#define NOTIFY_UI_LOCKSTATE    "com.apple.springboard.lockstate"
#define NOTIFY_LS_APP_CHANGED  "com.apple.LaunchServices.ApplicationsChanged"

// Removed notification handlers as notifications are removed
// static void LaunchServicesApplicationStateChanged(...) { ... }
// static void SpringBoardLockStatusChanged(...) { ... }

#pragma mark - NetworkSpeed13

// Removed unused defines and static variables related to appearance/interactivity/network speed
// #define IDLE_INTERVAL 3.0
// #define UPDATE_INTERVAL 1.0
// static const double HUD_MIN_FONT_SIZE = 9.0;
// static const double HUD_MAX_FONT_SIZE = 10.0;
// static const double HUD_MIN_CORNER_RADIUS = 4.5;
// static const double HUD_MAX_CORNER_RADIUS = 5.0;
// static double HUD_FONT_SIZE = 8.0; // Will use fixed value
// static UIFontWeight HUD_FONT_WEIGHT = UIFontWeightRegular; // Not needed
// static CGFloat HUD_INACTIVE_OPACITY = 0.667; // HUD will be fully opaque

// typedef struct { ... } UpDownBytes; // Removed
// Removed functions related to network speed

#pragma mark - HUDRootViewController

// Removed interface extension for orientation
// @interface HUDRootViewController (Troll) ... @end

// static const CACornerMask kCornerMaskBottom = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner; // Unused
// static const CACornerMask kCornerMaskAll = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner; // Unused

@implementation HUDRootViewController {
    // Removed instance variables related to user defaults, interactivity, orientation, screenshot protection, lock view
    // NSMutableDictionary *_userDefaults;
    NSMutableArray <NSLayoutConstraint *> *_constraints; // Keep for managing constraints
    UIBlurEffect *_blurEffect;
    UIVisualEffectView *_blurView;
    // ScreenshotInvisibleContainer *_containerView;
    UIView *_contentView;
    UIView *_redSquareView;
    // UIImageView *_lockedView;
    // UITapGestureRecognizer *_tapGestureRecognizer;
    // UIPanGestureRecognizer *_panGestureRecognizer;
    // UIImpactFeedbackGenerator *_impactFeedbackGenerator;
    // UINotificationFeedbackGenerator *_notificationFeedbackGenerator;
    // BOOL _isFocused;
    // NSLayoutConstraint *_topConstraint;
    // NSLayoutConstraint *_centerXConstraint;
    // NSLayoutConstraint *_leadingConstraint;
    // NSLayoutConstraint *_trailingConstraint;
    // UIInterfaceOrientation _orientation;
    // FBSOrientationObserver *_orientationObserver;
}

// Removed all methods related to notifications, user defaults, and appearance settings
// - (void)registerNotifications { ... }
// - (void)observeValueForKeyPath:(NSString *)keyPath ... { ... }
// - (void)loadUserDefaults:(BOOL)forceReload { ... }
// - (void)saveUserDefaults { ... }
// - (void)reloadUserDefaults { ... }
// + (BOOL)passthroughMode { ... } // Will be handled in HUDMainWindow.mm
// - (BOOL)isLandscapeOrientation { ... }
// - (HUDUserDefaultsKey)selectedModeKeyForCurrentOrientation { ... }
// - (HUDPresetPosition)selectedModeForCurrentOrientation { ... }
// - (BOOL)singleLineMode { ... }
// - (BOOL)usesBitrate { ... }
// - (BOOL)usesArrowPrefixes { ... }
// - (BOOL)usesLargeFont { ... }
// - (BOOL)usesRotation { ... }
// - (BOOL)usesInvertedColor { ... }
// - (BOOL)keepInPlace { ... }
// - (BOOL)hideAtSnapshot { ... }
// - (CGFloat)currentPositionY { ... }
// - (void)setCurrentPositionY:(CGFloat)positionY { ... }
// - (CGFloat)currentLandscapePositionY { ... }
// - (void)setCurrentLandscapePositionY:(CGFloat)positionY { ... }
// - (NSDictionary *)extraUserDefaultsDictionary { ... }
// - (BOOL)usesCustomFontSize { ... }
// - (CGFloat)realCustomFontSize { ... }
// - (BOOL)usesCustomOffset { ... }
// - (CGFloat)realCustomOffsetX { ... }
// - (CGFloat)realCustomOffsetY { ... }

- (instancetype)init {
    self = [super init];
    if (self) {
        _constraints = [NSMutableArray array];
        // Removed registerNotifications call
        // Removed orientation observer setup
    }
    return self;
}

- (void)dealloc {
    // Removed orientation observer invalidation
    // If ARC is not enabled, would need [super dealloc] and release ivars
}

// Removed updateSpeedLabel method
- (void)viewDidLoad {
    [super viewDidLoad];
    /* Setup simplified HUD view */

    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_contentView];

    // Keep blur effect for background
    _blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    _blurView = [[UIVisualEffectView alloc] initWithEffect:_blurEffect];
    _blurView.layer.cornerRadius = 4.5; // Fixed corner radius
    _blurView.layer.masksToBounds = YES;
    _blurView.translatesAutoresizingMaskIntoConstraints = NO;
    // Removed ScreenshotInvisibleContainer, add blurView directly
    [_contentView addSubview:_blurView];

    // Initialize Red Square View
    _redSquareView = [[UIView alloc] init];
    _redSquareView.backgroundColor = [UIColor redColor];
    _redSquareView.translatesAutoresizingMaskIntoConstraints = NO;
    [_blurView.contentView addSubview:_redSquareView]; // Add to blur view's content

    // Removed _lockedView setup
    // Removed gesture recognizer setup
    // Removed setUserInteractionEnabled (contentView is not interactive)
    // Removed reloadUserDefaults call

    // Setup constraints once
    [self updateViewConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // No actions needed on appear for static HUD
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // No actions needed on disappear for static HUD
}

// Rewritten to set fixed constraints for a static HUD
- (void)updateViewConstraints {
    [super updateViewConstraints];

    [NSLayoutConstraint deactivateConstraints:_constraints];
    [_constraints removeAllObjects];

    // --- Define Fixed Values ---
    CGFloat redSquareSize = 20.0;
    CGFloat blurPaddingHorizontal = 10.0;
    CGFloat blurPaddingVertical = 5.0;
    CGFloat topMargin = 5.0; // Margin from top safe area

    // --- Red Square Constraints (Fixed Size, Centered in Blur View) ---
    [_constraints addObjectsFromArray:@[
        [_redSquareView.centerXAnchor constraintEqualToAnchor:_blurView.contentView.centerXAnchor],
        [_redSquareView.centerYAnchor constraintEqualToAnchor:_blurView.contentView.centerYAnchor],
        [_redSquareView.widthAnchor constraintEqualToConstant:redSquareSize],
        [_redSquareView.heightAnchor constraintEqualToConstant:redSquareSize]
    ]];

    // --- Blur View Constraints (Wrap Red Square) ---
    [_constraints addObjectsFromArray:@[
        [_blurView.topAnchor constraintEqualToAnchor:_redSquareView.topAnchor constant:-blurPaddingVertical],
        [_blurView.bottomAnchor constraintEqualToAnchor:_redSquareView.bottomAnchor constant:blurPaddingVertical],
        [_blurView.leadingAnchor constraintEqualToAnchor:_redSquareView.leadingAnchor constant:-blurPaddingHorizontal],
        [_blurView.trailingAnchor constraintEqualToAnchor:_redSquareView.trailingAnchor constant:blurPaddingHorizontal]
    ]];

    // --- Content View Constraints (Position the Blur View - Top Center) ---
    // Add constraints relative to _contentView containing _blurView
     [_constraints addObjectsFromArray:@[
        [_blurView.topAnchor constraintEqualToAnchor:_contentView.topAnchor],
        [_blurView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor],
        [_blurView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor],
        [_blurView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor]
    ]];

    // Position _contentView itself (Top Center of safe area)
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [_constraints addObjectsFromArray:@[
        [_contentView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:topMargin],
        [_contentView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor]
        // Width/Height are determined by _blurView wrapping _redSquareView
    ]];

    [NSLayoutConstraint activateConstraints:_constraints];
}

// Removed orientation update method
// - (void)updateOrientation:(UIInterfaceOrientation)orientation ... { ... }

// Simplified animation removal
- (void)removeAllAnimations {
    [_contentView.layer removeAllAnimations];
    [_blurView.layer removeAllAnimations];
    [_redSquareView.layer removeAllAnimations];
    // Removed _lockedView animation removal
}

// Removed gesture recognizer methods
// - (void)resetGestureRecognizers { ... }
// - (void)onFocus:(UIView *)sender { ... }
// - (void)keepFocus:(UIView *)sender { ... }
// - (void)onBlur:(UIView *)sender { ... }
// - (void)tapGestureRecognized:(UITapGestureRecognizer *)sender { ... }
// - (void)panGestureRecognized:(UIPanGestureRecognizer *)sender { ... }

// Removed timer methods

@end