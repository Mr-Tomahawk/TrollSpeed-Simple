//
//  HUDRootViewController.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HUDRootViewController : UIViewController
// + (BOOL)passthroughMode; // Removed as it's no longer implemented or used
- (void)updateViewConstraints;

@end

NS_ASSUME_NONNULL_END