# Implementing Gesture-Controlled HUD Visibility

This document outlines how a 3-finger tap gesture was implemented in the main launcher application to toggle the visibility of an external HUD (Heads-Up Display) process. The communication between the launcher app and the HUD process is achieved using Darwin notifications.

## Changes Made to This Project (RedSquareHUD)

To enable gesture-controlled visibility for the RedSquareHUD, the following modifications were implemented:

1.  **Shared Notification Constant:**
    *   A unique Darwin notification name, `kToggleHUDVisibilityNotificationName` (e.g., `"com.yourcompany.simplehud.toggleVisibility"`), was defined as a static `NSString` constant.
    *   This constant was placed in the `RedSquareHUD-Prefix.pch` file to make it accessible to both the main launcher application and the HUD process.

2.  **Main Launcher Application (e.g., `Simple` project):**
    *   **File:** `RootViewController.h`
        *   (Initially, the constant was also declared here but was removed to avoid redefinition errors as the prefix header handles global inclusion.)
    *   **File:** `RootViewController.mm`
        *   Imported `<notify.h>`.
        *   In the `viewDidLoad` method:
            *   A `UITapGestureRecognizer` was created and configured for a 3-finger, 1-tap gesture.
            *   This gesture recognizer was added to the root view controller's main view (`self.view`).
            *   The action for this gesture was set to a new method, `handleHudVisibilityToggleGesture:`.
        *   Implemented the `handleHudVisibilityToggleGesture:(UITapGestureRecognizer *)gesture` method:
            *   When the gesture is recognized (state `UIGestureRecognizerStateEnded`), it posts a Darwin notification using `notify_post([kToggleHUDVisibilityNotificationName UTF8String]);`.

3.  **External HUD Process (e.g., `RedSquareHUD` process):**
    *   **File:** `HUDMainApplicationDelegate.mm`
        *   Imported `<notify.h>`.
        *   Added an integer instance variable (e.g., `_visibilityToggleToken`) to store the token from the Darwin notification registration.
        *   In the `application:didFinishLaunchingWithOptions:` method:
            *   Registered a listener for the `kToggleHUDVisibilityNotificationName` Darwin notification using `notify_register_dispatch`.
            *   The callback block for this notification calls a new method, `handleVisibilityToggleNotification`.
        *   Implemented the `handleVisibilityToggleNotification` method:
            *   This method toggles the `hidden` property of the HUD's main window (e.g., `self.window.hidden = !self.window.hidden;`). This makes the HUD appear or disappear without terminating its process.
        *   Implemented a `dealloc` method to unregister the Darwin notification listener using `notify_cancel(_visibilityToggleToken);` when the delegate is deallocated.

## Replicating This for Your External Drawing Project

If you have a main application and a separate external process that handles on-screen drawing (your HUD), you can implement a similar gesture control system as follows:

**Assumptions:**
*   You have a "Launcher App" and an "External HUD App."
*   You are comfortable working with Objective-C and Theos (or a similar build system).

**Steps:**

1.  **Define a Unique Notification Name:**
    *   Choose a unique string for your Darwin notification (e.g., `"com.yourproject.hud.toggleVisibility"`).
    *   Define this as a constant (e.g., `static NSString * const kMyHUDToggleNotification = @"...";`).
    *   **Best Practice:** Place this constant in a shared header file or a prefix header (`.pch`) that is included by both your Launcher App and your External HUD App. This ensures consistency and avoids typos.

2.  **Launcher App Modifications:**
    *   **In your View Controller responsible for gesture detection (e.g., `RootViewController.m`):**
        *   Ensure `<notify.h>` is imported.
        *   In `viewDidLoad` (or a similar setup method):
            ```objective-c
            // #import <notify.h> // At the top of your file
            // extern NSString * const kMyHUDToggleNotification; // If defined in a shared .h, or ensure .pch includes it

            // ... inside viewDidLoad ...
            UITapGestureRecognizer *toggleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleToggleGesture:)];
            toggleGesture.numberOfTouchesRequired = 3; // Or your desired number of fingers
            toggleGesture.numberOfTapsRequired = 1;    // Or your desired number of taps
            [self.view addGestureRecognizer:toggleGesture];
            // [toggleGesture release]; // If not using ARC
            ```
        *   Implement the gesture handler method:
            ```objective-c
            - (void)handleToggleGesture:(UITapGestureRecognizer *)gesture {
                if (gesture.state == UIGestureRecognizerStateEnded) {
                    NSLog(@"[LauncherApp] Gesture detected, posting notification to toggle HUD.");
                    notify_post([kMyHUDToggleNotification UTF8String]);
                }
            }
            ```

3.  **External HUD App Modifications:**
    *   **In your HUD's Application Delegate (e.g., `HUDAppDelegate.m`):**
        *   Ensure `<notify.h>` is imported.
        *   Add an instance variable to store the notification token:
            ```objective-c
            // @implementation HUDAppDelegate {
            //     int _hudToggleNotificationToken;
            // }
            ```
        *   In `application:didFinishLaunchingWithOptions:` (after your HUD window is set up):
            ```objective-c
            // #import <notify.h> // At the top of your file
            // extern NSString * const kMyHUDToggleNotification; // If defined in a shared .h, or ensure .pch includes it

            // ... inside application:didFinishLaunchingWithOptions: ...
            __weak typeof(self) weakSelf = self; // Important for the block
            notify_register_dispatch(
                [kMyHUDToggleNotification UTF8String],
                &_hudToggleNotificationToken,      // Address of your token variable
                dispatch_get_main_queue(),         // Dispatch to main queue for UI updates
                ^(int token) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf) {
                        [strongSelf handleHUDToggle];
                    }
                }
            );
            ```
        *   Implement the method to handle the notification:
            ```objective-c
            - (void)handleHUDToggle {
                NSLog(@"[HUDApp] Received toggle notification.");
                // Assuming 'self.hudWindow' is your HUD's main UIWindow
                if (self.hudWindow) {
                    self.hudWindow.hidden = !self.hudWindow.hidden;
                    NSLog(@"[HUDApp] HUD visibility set to: %s", self.hudWindow.hidden ? "Hidden" : "Visible");
                }
            }
            ```
        *   Implement `dealloc` to clean up the notification listener:
            ```objective-c
            - (void)dealloc {
                if (_hudToggleNotificationToken) {
                    notify_cancel(_hudToggleNotificationToken);
                }
                // [super dealloc]; // If not using ARC
            }
            ```

**Important Considerations:**

*   **Error Handling:** The example code is basic. You might want to add more robust error checking.
*   **Window Level:** Ensure your HUD window's level is set appropriately to appear above other content if needed.
*   **Process Management:** This guide only covers toggling visibility. Spawning and killing the HUD process are separate concerns.
*   **ARC/Manual Retain Release:** The code snippets assume ARC (Automatic Reference Counting). If you are using Manual Retain Release, adjust memory management accordingly (e.g., `retain`, `release`, `autorelease`).
*   **Alternative Communication:** While Darwin notifications are suitable for simple toggles, for more complex data exchange between processes, you might explore other IPC (Inter-Process Communication) mechanisms like XPC services.

By following these steps, you can implement a gesture-based visibility toggle for your external drawing project, similar to how it was done in this project.
