//
//  RootViewController.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>
// #import "TrollSpeed-Swift.h" // Removed - No longer uses Swift delegate

NS_ASSUME_NONNULL_BEGIN

@interface RootViewController : UIViewController // Removed <TSSettingsControllerDelegate>
@property (nonatomic, strong) UIView *backgroundView;
// + (void)setShouldToggleHUDAfterLaunch:(BOOL)flag; // Removed as URL/Shortcut handling was removed
- (void)reloadMainButtonState;
@end

NS_ASSUME_NONNULL_END