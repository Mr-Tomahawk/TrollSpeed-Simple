#import "MainButton.h"

@implementation MainButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = highlighted ? CGAffineTransformMakeScale(0.95, 0.95) : CGAffineTransformIdentity;
    }];
}

@end
