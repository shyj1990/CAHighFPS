#import <UIKit/UIKit.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>

@interface CAHighFPSLogoHeaderCell : PSTableCell
- (instancetype)initWithSpecifier:(PSSpecifier *)specifier;
@end

@implementation CAHighFPSLogoHeaderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if (self)
        [self ca_setup];
    return self;
}

// 兼容运行时经 initWithSpecifier: 创建 cell 的路径（该选择器在新头文件中已无声明）
- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
    return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil specifier:specifier];
}

- (void)ca_setup {
    if (_logoView)
        return;
    self.backgroundColor = [UIColor clearColor];
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"logo" ofType:@"png"];
    UIImage *image = path ? [UIImage imageWithContentsOfFile:path] : nil;
    _logoView = [[UIImageView alloc] initWithImage:image];
    _logoView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_logoView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat side = 88.0, height = 116.0;
    _logoView.frame = CGRectMake((self.bounds.size.width - side) / 2.0, (height - side) / 2.0, side, side);
}

- (CGFloat)preferredHeightForSpecifier:(PSSpecifier *)specifier {
    return 116.0;
}

@end
