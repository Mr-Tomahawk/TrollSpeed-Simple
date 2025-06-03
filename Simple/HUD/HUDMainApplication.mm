#import <notify.h>
#import "pac_helper.h"
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
                    [self terminateWithSuccess];
                }];
            });
        }
    }
    return self;
}

@end