//
//  HUDApp.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <notify.h>
// #import <mach-o/dyld.h> // Unused
#import <sys/utsname.h>
#import <objc/runtime.h>

// #import "IOKit+SPI.h" // Unused
#import "HUDHelper.h"
// #import "TSEventFetcher.h" // Removed as event fetching is not needed
#import "BackboardServices.h"
// #import "AXEventRepresentation.h" // Removed as _HUDEventCallback was removed
#import "UIApplication+Private.h"

#import "MainApplication.h"         // Added for custom application class
#import "MainApplicationDelegate.h" // Added for custom app delegate (already used by name)

#define PID_PATH "/var/mobile/Library/Caches/com.user.redsquarehud.pid" // Updated bundle ID

// Removed unused mDeviceModel function
// static __used
// NSString *mDeviceModel(void) { ... }

// Removed _HUDEventCallback function as it's not needed for static HUD

int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        log_debug(OS_LOG_DEFAULT, "launched argc %{public}d, argv[1] %{public}s", argc, argc > 1 ? argv[1] : "NULL");

        if (argc <= 1) {
            return UIApplicationMain(argc, argv, NSStringFromClass([MainApplication class]), NSStringFromClass([MainApplicationDelegate class]));
        }

        NSString *pidPath;
#if !TARGET_OS_SIMULATOR
        pidPath = @(PID_PATH); // Directly create NSString from C string literal
#else
        pidPath = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject path] stringByAppendingPathComponent:@"ch.xxtou.hudapp.pid"];
#endif

        if (strcmp(argv[1], "-hud") == 0)
        {
            pid_t pid = getpid();
            pid_t pgid = getgid();
            (void)pgid;
            log_debug(OS_LOG_DEFAULT, "HUD pid %d, pgid %d", pid, pgid);

            NSString *pidString = [NSString stringWithFormat:@"%d", pid];
            [pidString writeToFile:pidPath
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:nil];

            [UIScreen initialize];
            CFRunLoopGetCurrent();

            GSInitialize();
            BKSDisplayServicesStart();
            UIApplicationInitialize();

            UIApplicationInstantiateSingleton(objc_getClass("HUDMainApplication"));
            static id<UIApplicationDelegate> appDelegate = [[objc_getClass("HUDMainApplicationDelegate") alloc] init];
            [UIApplication.sharedApplication setDelegate:appDelegate];
            [UIApplication.sharedApplication _accessibilityInit];

            [NSRunLoop currentRunLoop];
            // Removed BKSHIDEventRegisterEventCallback call

            if (@available(iOS 15.0, *)) {
                GSEventInitialize(0);
                GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
            }

            [UIApplication.sharedApplication __completeAndRunAsPlugin];

            // Notify the launcher that the HUD has successfully launched
            log_debug(OS_LOG_DEFAULT, "HUD process posting NOTIFY_LAUNCHED_HUD");
            notify_post(NOTIFY_LAUNCHED_HUD);

            // Removed SBSpringBoardDidLaunchNotification handler block for simplicity
            // static int _springboardBootToken;
            // notify_register_dispatch(...) { ... };

            CFRunLoopRun();
            return EXIT_SUCCESS;
        }
        else if (strcmp(argv[1], "-exit") == 0)
        {
            NSString *pidString = [NSString stringWithContentsOfFile:pidPath
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];

            if (pidString)
            {
                pid_t pid = (pid_t)[pidString intValue];
                kill(pid, SIGKILL);
                unlink([pidPath UTF8String]);
            }

            return EXIT_SUCCESS;
        }
        else if (strcmp(argv[1], "-check") == 0)
        {
            NSString *pidString = [NSString stringWithContentsOfFile:pidPath
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];

            if (pidString)
            {
                pid_t pid = (pid_t)[pidString intValue];
                int killed = kill(pid, 0);
                return (killed == 0 ? EXIT_FAILURE : EXIT_SUCCESS);
            }
            else return EXIT_SUCCESS;  // No PID file, so HUD is not running
        }
    }
}