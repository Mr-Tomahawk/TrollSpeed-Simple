# Analysis of Multi-Finger Double Tap Gesture in HuyJIT-ModMenu

This document details how the 3-finger double tap (to open menu) and 2-finger double tap (to disable menu) functionalities are implemented in the studied project and provides instructions on how to replicate this mechanism for custom on-screen drawing.

## How it Works

The core logic for gesture recognition is found in `PubgLoad.mm`.

1.  **Initialization (`+ (void)load` in `PubgLoad.mm`):
    *   This class method is automatically invoked when `PubgLoad` is loaded by the Objective-C runtime.
    *   It uses `dispatch_after` to delay the setup by 3 seconds, likely to ensure the application's main UI is initialized and ready.
    *   An instance of `PubgLoad` is created.
    *   Methods `initTapGes` (for the 3-finger gesture) and `initTapGes2` (for the 2-finger gesture) are called to set up the gesture recognizers.

2.  **Gesture Recognizer Setup:**
    *   **`-(void)initTapGes` (3-Finger Double Tap - Show Menu):**
        *   A `UITapGestureRecognizer` is instantiated.
        *   `numberOfTapsRequired` is set to `2`.
        *   `numberOfTouchesRequired` is set to `3`.
        *   The gesture recognizer is added to `[JHPP currentViewController].view`. `JHPP` appears to be a custom utility class/method for obtaining a reference to the currently active view controller.
        *   The target for this gesture is the `PubgLoad` instance itself, and the action selector is `tapIconView`.
    *   **`-(void)initTapGes2` (2-Finger Double Tap - Hide Menu):**
        *   Another `UITapGestureRecognizer` is instantiated.
        *   `numberOfTapsRequired` is set to `2`.
        *   `numberOfTouchesRequired` is set to `2`.
        *   This recognizer is also added to `[JHPP currentViewController].view`.
        *   The target is the `PubgLoad` instance, and the action selector is `tapIconView2`.

3.  **Gesture Action Handling:**
    *   **`-(void)tapIconView` (Action for 3-finger double tap):**
        *   This method is invoked when the 3-finger double tap is detected.
        *   It ensures that an instance of `ImGuiDrawView` (referred to as `_vna`) exists. `ImGuiDrawView` is responsible for rendering the ImGui menu.
        *   It calls the static method `[ImGuiDrawView showChange:true];`. This method in `ImGuiDrawView.mm` sets a static boolean variable (likely named `MenDeal`) to `true`.
        *   The `ImGuiDrawView`'s view (`_vna.view`) is added as a subview to the main application's root view controller's view: `[[UIApplication sharedApplication].windows[0].rootViewController.view addSubview:_vna.view];`.
    *   **`-(void)tapIconView2` (Action for 2-finger double tap):**
        *   This method is invoked when the 2-finger double tap is detected.
        *   It also ensures the `ImGuiDrawView` instance (`_vna`) exists.
        *   It calls `[ImGuiDrawView showChange:false];`, setting the `MenDeal` flag in `ImGuiDrawView.mm` to `false`.
        *   Similar to `tapIconView`, it adds `_vna.view` as a subview.

4.  **Menu Visibility Control (`ImGuiDrawView.mm`):
    *   The `ImGuiDrawView` class contains the actual ImGui rendering logic in its `drawInMTKView:` method.
    *   This method checks the state of the `MenDeal` static boolean. If `MenDeal` is `true`, the ImGui menu is rendered. If `false`, the menu is not rendered, effectively hiding it.
    *   The view itself (`_vna.view`) might remain in the view hierarchy, but its content (the menu) is conditionally drawn based on `MenDeal`.

## How to Replicate for Custom Drawing

To replicate this gesture-controlled visibility for any custom content you want to draw on screen, follow these steps:

1.  **Create Your Custom Overlay View:**
    *   Create a `UIView` subclass (e.g., `MyCustomOverlayView`).
    *   Implement its drawing logic (e.g., in `drawRect:`) or add subviews to it to display your desired content.
    *   Add a method or property to control its visibility, for example:
        ```objective-c
        // MyCustomOverlayView.h
        @interface MyCustomOverlayView : UIView
        @property (nonatomic, assign, getter=isVisible) BOOL visible;
        - (void)showView;
        - (void)hideView;
        @end

        // MyCustomOverlayView.m
        @implementation MyCustomOverlayView
        - (void)setVisible:(BOOL)visible {
            _visible = visible;
            self.hidden = !visible;
            // Or trigger a redraw if you are custom drawing and visibility affects it
            // [self setNeedsDisplay]; 
        }
        - (void)showView {
            self.visible = YES;
        }
        - (void)hideView {
            self.visible = NO;
        }
        // ... your drawing code ...
        @end
        ```

2.  **Create a Gesture Controller Class:**
    *   Create an Objective-C class (e.g., `GestureController`). This class will manage the gesture recognizers and the overlay view.
    *   Declare a property for your custom overlay view:
        ```objective-c
        // GestureController.h
        #import <UIKit/UIKit.h>
        #import "MyCustomOverlayView.h"

        @interface GestureController : NSObject
        @property (nonatomic, strong) MyCustomOverlayView *overlayView;
        + (instancetype)sharedController;
        - (void)setupGesturesAndOverlayInWindow:(UIWindow *)window; // Or pass a specific view
        @end
        ```

3.  **Initialize Overlay and Setup Gestures:**
    *   In `GestureController.m`:
        ```objective-c
        // GestureController.m
        @implementation GestureController

        + (instancetype)sharedController {
            static GestureController *shared = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                shared = [[self alloc] init];
            });
            return shared;
        }

        - (void)setupGesturesAndOverlayInView:(UIView *)targetView {
            if (!self.overlayView) {
                self.overlayView = [[MyCustomOverlayView alloc] initWithFrame:targetView.bounds];
                self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                self.overlayView.visible = NO; // Start hidden
                [targetView addSubview:self.overlayView];
            }

            // Setup 3-finger double tap to show
            UITapGestureRecognizer *showGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleShowGesture:)];
            showGesture.numberOfTapsRequired = 2;
            showGesture.numberOfTouchesRequired = 3;
            [targetView addGestureRecognizer:showGesture];

            // Setup 2-finger double tap to hide
            UITapGestureRecognizer *hideGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHideGesture:)];
            hideGesture.numberOfTapsRequired = 2;
            hideGesture.numberOfTouchesRequired = 2;
            [targetView addGestureRecognizer:hideGesture];
        }

        - (void)handleShowGesture:(UITapGestureRecognizer *)gesture {
            [self.overlayView showView];
            [self.overlayView.superview bringSubviewToFront:self.overlayView]; // Ensure it's on top
            NSLog(@"Show gesture triggered");
        }

        - (void)handleHideGesture:(UITapGestureRecognizer *)gesture {
            [self.overlayView hideView];
            NSLog(@"Hide gesture triggered");
        }

        @end
        ```

4.  **Integrate into Your Application:**
    *   In your `AppDelegate` or a suitable place after your main UI is set up (e.g., after the root view controller's view is loaded):
        ```objective-c
        // AppDelegate.m (or equivalent)
        #import "GestureController.h"

        - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
            // ... your existing setup ...

            // Assuming self.window is your main UIWindow
            // Or get the rootViewController's view:
            // UIView *targetView = self.window.rootViewController.view;
            // It's often best to add global gestures to the window itself.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                 [[GestureController sharedController] setupGesturesAndOverlayInView:self.window];
            });

            return YES;
        }
        ```

**Key Considerations for Replication:**

*   **Target View for Gestures:** Adding gesture recognizers to the `UIWindow` makes them global. If you add them to a specific `UIView`, they will only work when that view (or its subviews) can receive touch events.
*   **View Hierarchy for Overlay:** Adding your `MyCustomOverlayView` to the `UIWindow` will place it above all other content in that window. Adding it to a specific view controller's view will scope it to that controller.
*   **Gesture Conflicts:** If other parts of your application use similar gestures, you might need to implement `UIGestureRecognizerDelegate` methods to manage how gestures interact (e.g., `gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:`).
*   **Timing:** Ensure the view to which you add gesture recognizers is already part of the view hierarchy and has a frame. Using `dispatch_after` as in the original code or setting up in `viewDidAppear:` of a view controller can help ensure this.
*   **`JHPP currentViewController`:** The original code uses a custom `JHPP` utility. For general replication, attaching gestures to `[UIApplication sharedApplication].keyWindow` or `self.window.rootViewController.view` is more common. If you need to dynamically find the topmost view controller, you'd have to implement that logic.

This approach provides a robust way to toggle the visibility of custom on-screen content using multi-finger double tap gestures, similar to the analyzed project.
