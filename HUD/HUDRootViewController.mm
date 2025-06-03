#import "HUDRootViewController.h"

@implementation HUDRootViewController {
    NSMutableArray <NSLayoutConstraint *> *_constraints;
    UIBlurEffect *_blurEffect;
    UIVisualEffectView *_blurView;
    UIView *_contentView;
    UIView *_redSquareView;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _constraints = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_contentView];

    _blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    _blurView = [[UIVisualEffectView alloc] initWithEffect:_blurEffect];
    _blurView.layer.cornerRadius = 4.5;
    _blurView.layer.masksToBounds = YES;
    _blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_blurView];

    _redSquareView = [[UIView alloc] init];
    _redSquareView.backgroundColor = [UIColor redColor];
    _redSquareView.translatesAutoresizingMaskIntoConstraints = NO;
    [_blurView.contentView addSubview:_redSquareView];

    [self updateViewConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];

    [NSLayoutConstraint deactivateConstraints:_constraints];
    [_constraints removeAllObjects];

    CGFloat redSquareSize = 20.0;
    CGFloat blurPaddingHorizontal = 10.0;
    CGFloat blurPaddingVertical = 5.0;
    CGFloat topMargin = 5.0;

    [_constraints addObjectsFromArray:@[
        [_redSquareView.centerXAnchor constraintEqualToAnchor:_blurView.contentView.centerXAnchor],
        [_redSquareView.centerYAnchor constraintEqualToAnchor:_blurView.contentView.centerYAnchor],
        [_redSquareView.widthAnchor constraintEqualToConstant:redSquareSize],
        [_redSquareView.heightAnchor constraintEqualToConstant:redSquareSize]
    ]];

    [_constraints addObjectsFromArray:@[
        [_blurView.topAnchor constraintEqualToAnchor:_redSquareView.topAnchor constant:-blurPaddingVertical],
        [_blurView.bottomAnchor constraintEqualToAnchor:_redSquareView.bottomAnchor constant:blurPaddingVertical],
        [_blurView.leadingAnchor constraintEqualToAnchor:_redSquareView.leadingAnchor constant:-blurPaddingHorizontal],
        [_blurView.trailingAnchor constraintEqualToAnchor:_redSquareView.trailingAnchor constant:blurPaddingHorizontal]
    ]];

     [_constraints addObjectsFromArray:@[
        [_blurView.topAnchor constraintEqualToAnchor:_contentView.topAnchor],
        [_blurView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor],
        [_blurView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor],
        [_blurView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor]
    ]];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [_constraints addObjectsFromArray:@[
        [_contentView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:topMargin],
        [_contentView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor]
    ]];

    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)removeAllAnimations {
    [_contentView.layer removeAllAnimations];
    [_blurView.layer removeAllAnimations];
    [_redSquareView.layer removeAllAnimations];
}

@end