#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Notification constants
extern NSString * const kToggleHUDAfterLaunchNotificationName;
extern NSString * const kToggleHUDAfterLaunchNotificationActionKey;
extern NSString * const kToggleHUDAfterLaunchNotificationActionToggleOn;
extern NSString * const kToggleHUDAfterLaunchNotificationActionToggleOff;

@interface RootViewController : UIViewController
@property (nonatomic, strong) UIView *backgroundView;
- (void)reloadMainButtonState;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)shouldToggle;
@end

NS_ASSUME_NONNULL_END