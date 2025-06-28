//
//  HUDMainApplication.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <notify.h>
// #import <pthread.h> // Unused
// #import <mach/mach.h> // Unused
// #import <mach-o/dyld.h> // Unused
#import <objc/runtime.h>

#import "pac_helper.h"
// #import "UIEventFetcher.h" // Removed as event handling logic was removed
// #import "UIEventDispatcher.h" // Removed as event handling logic was removed
#import "HUDMainApplication.h"
#import "UIApplication+Private.h"

@implementation HUDMainApplication

- (instancetype)init
{
    if (self = [super init])
    {
        log_debug(OS_LOG_DEFAULT, "- [HUDMainApplication init]");

        {
            int outToken;
            notify_register_dispatch(NOTIFY_DISMISSAL_HUD, &outToken, dispatch_get_main_queue(), ^(int token) {
                notify_cancel(token);
                
                // Fade out the HUD window
                [UIView animateWithDuration:FADE_OUT_DURATION animations:^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    [[self.windows firstObject] setAlpha:0.0];
#pragma clang diagnostic pop
                } completion:^(BOOL finished) {
                    // Terminate the HUD app
                    [self terminateWithSuccess];
                }];
            });
        }

        // Removed complex event dispatcher/fetcher setup logic (lines 46-137)
        // as the simplified HUD is non-interactive.
    }
    return self;
}

@end