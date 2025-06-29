#import "HUDRootViewController.h"
#import "FBSOrientationObserver.h"
#import "FBSOrientationUpdate.h"
#import <objc/runtime.h>

static inline CGFloat orientationAngle(UIInterfaceOrientation orientation) {
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
        case UIInterfaceOrientationLandscapeLeft:
            return -M_PI_2;
        case UIInterfaceOrientationLandscapeRight:
            return M_PI_2;
        default:
            return 0;
    }
}

static inline CGRect orientationBounds(UIInterfaceOrientation orientation, CGRect bounds) {
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return CGRectMake(0, 0, bounds.size.height, bounds.size.width);
        default:
            return bounds;
    }
}

@implementation HUDRootViewController {
    UIView *_redSquareView;
    BOOL _isBlue;
    UIPanGestureRecognizer *_panGestureRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;
    FBSOrientationObserver *_orientationObserver;
    UIInterfaceOrientation _orientation;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isBlue = NO;
        _orientation = UIInterfaceOrientationPortrait;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self createDraggableRedSquare];
    
    // setup orientation observer for following landscape
    [self setupFBSOrientationObserver];
}

- (void)dealloc {
    [_orientationObserver invalidate];
}

- (void)createDraggableRedSquare {
    CGFloat width = 50.0;
    CGFloat height = 30.0;
    _redSquareView = [[UIView alloc] initWithFrame:CGRectMake(50, 100, width, height)];
    _redSquareView.backgroundColor = [UIColor redColor];
    _redSquareView.layer.cornerRadius = 4.0;
    _redSquareView.userInteractionEnabled = YES;
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(redSquarePanned:)];
    [_redSquareView addGestureRecognizer:_panGestureRecognizer];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(redSquareTapped:)];
    [_redSquareView addGestureRecognizer:_tapGestureRecognizer];
    
    [self loadSquarePosition];
    
    // add to self.view directly (keeping it simple)
    [self.view addSubview:_redSquareView];
}

- (void)redSquarePanned:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.view];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        // drag started
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(_redSquareView.center.x + translation.x,
                                       _redSquareView.center.y + translation.y);
        
        // dont let it go off screen
        CGFloat halfWidth = _redSquareView.frame.size.width / 2.0;
        CGFloat halfHeight = _redSquareView.frame.size.height / 2.0;
        CGSize screenSize = self.view.bounds.size;
        
        newCenter.x = MAX(halfWidth, MIN(screenSize.width - halfWidth, newCenter.x));
        newCenter.y = MAX(halfHeight, MIN(screenSize.height - halfHeight, newCenter.y));
        
        _redSquareView.center = newCenter;
        [sender setTranslation:CGPointZero inView:self.view];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [self saveSquarePosition];
    }
}

- (void)redSquareTapped:(UITapGestureRecognizer *)sender {
    _isBlue = !_isBlue;
    UIColor *newColor = _isBlue ? [UIColor blueColor] : [UIColor redColor];
    
    [UIView animateWithDuration:0.3 animations:^{
        self->_redSquareView.backgroundColor = newColor;
    }];
}

- (void)saveSquarePosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:_redSquareView.center.x forKey:@"redSquareX"];
    [defaults setDouble:_redSquareView.center.y forKey:@"redSquareY"];
    [defaults synchronize];
}

- (void)loadSquarePosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"redSquareX"] && [defaults objectForKey:@"redSquareY"]) {
        CGFloat x = [defaults doubleForKey:@"redSquareX"];
        CGFloat y = [defaults doubleForKey:@"redSquareY"];
        _redSquareView.center = CGPointMake(x, y);
        NSLog(@"🎯 Loaded square position: %@", NSStringFromCGPoint(_redSquareView.center));
    }
}

- (void)setupFBSOrientationObserver {
    _orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
    __weak HUDRootViewController *weakSelf = self;
    [_orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
        HUDRootViewController *strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf updateOrientation:(UIInterfaceOrientation)orientationUpdate.orientation 
                       animateWithDuration:orientationUpdate.duration];
        });
    }];
    NSLog(@"🎯 FBSOrientationObserver setup complete");
}

- (void)updateOrientation:(UIInterfaceOrientation)orientation animateWithDuration:(NSTimeInterval)duration {
    if (orientation == _orientation) {
        return;
    }
    
    _orientation = orientation;
    
    // follow mode - rotate entire HUD w/ device
    CGRect bounds = orientationBounds(orientation, [UIScreen mainScreen].bounds);
    [self.view setNeedsUpdateConstraints];
    [self.view setHidden:YES];  // hide during rotation so it doesnt look weird
    [self.view setBounds:bounds];
    
    [self resetGestureRecognizers];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        [weakSelf.view setTransform:CGAffineTransformMakeRotation(orientationAngle(orientation))];
    } completion:^(BOOL finished) {
        [weakSelf.view setHidden:NO];
        [weakSelf adjustRedSquareAfterOrientation];
    }];
}

- (void)resetGestureRecognizers {
    // reset gestures after orientation change (they get messed up otherwise)
    for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
        [recognizer setEnabled:NO];
        [recognizer setEnabled:YES];
    }
    if (_redSquareView) {
        for (UIGestureRecognizer *recognizer in _redSquareView.gestureRecognizers) {
            [recognizer setEnabled:NO];
            [recognizer setEnabled:YES];
        }
    }
}

- (void)adjustRedSquareAfterOrientation {
    if (_redSquareView) {
        CGFloat halfWidth = _redSquareView.frame.size.width / 2.0;
        CGFloat halfHeight = _redSquareView.frame.size.height / 2.0;
        CGSize screenSize = self.view.bounds.size;
        
        CGPoint currentCenter = _redSquareView.center;
        CGPoint adjustedCenter = CGPointMake(
            MAX(halfWidth, MIN(screenSize.width - halfWidth, currentCenter.x)),
            MAX(halfHeight, MIN(screenSize.height - halfHeight, currentCenter.y))
        );
        
        _redSquareView.center = adjustedCenter;
        [self saveSquarePosition];
    }
}



@end