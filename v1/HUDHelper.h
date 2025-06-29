//
//  HUDHelper.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// User Defaults Key definitions moved to RedSquareHUD-Prefix.pch

OBJC_EXTERN BOOL IsHUDEnabled(void);
OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);

// Removed SimulateMemoryPressure declaration
// #if DEBUG
// OBJC_EXTERN void SimulateMemoryPressure(void);
// #endif

// Removed GetStandardUserDefaults declaration
// OBJC_EXTERN NSUserDefaults *GetStandardUserDefaults(void);

NS_ASSUME_NONNULL_END