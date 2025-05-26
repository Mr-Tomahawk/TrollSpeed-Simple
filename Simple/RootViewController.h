//
//  RootViewController.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>
// #import "TrollSpeed-Swift.h" // Removed - No longer uses Swift delegate

NS_ASSUME_NONNULL_BEGIN

// Notification constants from Speed/sources/MainApplication.h
static NSString * const kToggleHUDAfterLaunchNotificationName = @"ch.xxtou.hudapp.notification.toggle-hud";
static NSString * const kToggleHUDAfterLaunchNotificationActionKey = @"action";
static NSString * const kToggleHUDAfterLaunchNotificationActionToggleOn = @"toggle_on";
static NSString * const kToggleHUDAfterLaunchNotificationActionToggleOff = @"toggle_off";

@interface RootViewController : UIViewController // Removed <TSSettingsControllerDelegate>
@property (nonatomic, strong) UIView *backgroundView;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag;
+ (BOOL)shouldToggleHUDAfterLaunch;
- (void)reloadMainButtonState;
@end

NS_ASSUME_NONNULL_END