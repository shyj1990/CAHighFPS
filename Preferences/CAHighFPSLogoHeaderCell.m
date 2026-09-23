#import <UIKit/UIKit.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>

@interface CAHighFPSLogoHeaderCell : PSTableCell
{
    UIImageView *_logoView;
}
@end

@implementation CAHighFPSLogoHeaderCell

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithSpecifier:specifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _logoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 88, 88)];
        _logoView.contentMode = UIViewContentModeScaleAspectFit;
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"logo" ofType:@"png"];
        if (path)
            _logoView.image = [UIImage imageWithContentsOfFile:path];
        [self addSubview:_logoView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height = [self preferredHeightForSpecifier:self.specifier];
    _logoView.center = CGPointMake(self.bounds.size.width / 2.0, height / 2.0);
}

- (CGFloat)preferredHeightForSpecifier:(PSSpecifier *)specifier {
    return 116.0;
}

@end
