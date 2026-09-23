#define CHECK_TARGET

#import <PSHeader/PS.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#define domain CFSTR("com.apple.UIKit")
#define whitelistKey CFSTR("CAHighFPS")
#define systemWideKey CFSTR("CAHighFPSSystemWide")
#define blacklistKey CFSTR("CAHighFPSBlacklist")
#define customFPSKey CFSTR("CAHighFPSCustomFPS")
#define metalKey CFSTR("CAHighFPSEnableMetal")

@interface CAMetalLayer (Private)
@property (assign) CGFloat drawableTimeoutSeconds;
@end

#ifndef __IPHONE_15_0
typedef struct {
    NSInteger minimum;
    NSInteger preferred;
    NSInteger maximum;
} CAFrameRateRange;
#endif

static NSInteger maxFPS = -1;
static NSInteger customFPS = 0;
static BOOL systemWide = NO;
static BOOL metalEnabled = YES;
static NSArray<NSString *> *whitelist;
static NSArray<NSString *> *blacklist;

static id copyPrefValue(CFStringRef prefKey) {
    CFTypeRef value = CFPreferencesCopyAppValue(prefKey, domain);
    if (value == NULL)
        value = CFPreferencesCopyValue(prefKey, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    return value ? (__bridge_transfer id)value : nil;
}

static void loadPreferences() {
    id systemWideValue = copyPrefValue(systemWideKey);
    systemWide = [systemWideValue isKindOfClass:[NSNumber class]] && [systemWideValue boolValue];

    id whitelistValue = copyPrefValue(whitelistKey);
    whitelist = [whitelistValue isKindOfClass:[NSArray class]] ? whitelistValue : nil;

    id blacklistValue = copyPrefValue(blacklistKey);
    blacklist = [blacklistValue isKindOfClass:[NSArray class]] ? blacklistValue : nil;

    id customFPSValue = copyPrefValue(customFPSKey);
    customFPS = [customFPSValue isKindOfClass:[NSNumber class]] ? (NSInteger)lround([customFPSValue doubleValue]) : 0;

    // Metal Hack 开关：未设置过时保持默认开启（与原版行为一致）
    id metalValue = copyPrefValue(metalKey);
    metalEnabled = (metalValue == nil) || ([metalValue isKindOfClass:[NSNumber class]] && [metalValue boolValue]);
}

static NSInteger getMaxFPS() {
    if (maxFPS == -1)
        maxFPS = [UIScreen mainScreen].maximumFramesPerSecond;
    return maxFPS;
}

static NSInteger getTargetFPS() {
    NSInteger max = getMaxFPS();
    if (customFPS <= 0 || customFPS >= max)
        return max;
    return customFPS;
}

static BOOL usesCustomFPS() {
    NSInteger max = getMaxFPS();
    return customFPS > 0 && customFPS < max;
}

static BOOL shouldEnableForBundleIdentifier(NSString *bundleIdentifier) {
    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"])
        return NO;
    if (systemWide)
        return ![blacklist containsObject:bundleIdentifier];
    return [whitelist containsObject:bundleIdentifier];
}

#pragma mark - CADisplayLink

%hook CADisplayLink

- (void)setFrameInterval:(NSInteger)interval {
    NSInteger target = getTargetFPS();
    NSInteger newInterval = (NSInteger)lround((double)getMaxFPS() / (double)target);
    %orig(newInterval < 1 ? 1 : newInterval);
    if ([self respondsToSelector:@selector(setPreferredFramesPerSecond:)])
        self.preferredFramesPerSecond = usesCustomFPS() ? target : 0;
}

- (void)setPreferredFramesPerSecond:(NSInteger)fps {
    %orig(usesCustomFPS() ? getTargetFPS() : 0);
}

- (void)setPreferredFrameRateRange:(CAFrameRateRange)range {
    NSInteger target = getTargetFPS();
    if (usesCustomFPS()) {
        // 自定义 FPS 时留出 15fps 缓冲带，避免钉死后偶发掉帧无余量
        range.minimum = MAX(1, target - 15);
        range.preferred = target;
        range.maximum = target;
    } else {
        // 保留 App 自身的下限（ProMotion 1-120Hz 自适应屏可进低帧档省电）
        range.minimum = MIN(range.minimum, 30);
        range.preferred = target;
        range.maximum = target;
    }
    %orig;
}

%end

#pragma mark - CAMetalLayer

// Metal Hack 组：可通过设置中的 Metal Hack 开关整体启停
%group Metal

%hook CAMetalLayer

- (NSUInteger)maximumDrawableCount {
    return 2;
}

- (void)setMaximumDrawableCount:(NSUInteger)count {
    %orig(2);
}

%end

#pragma mark - Metal Advanced Hack

%hook CAMetalDrawable

- (void)presentAfterMinimumDuration:(CFTimeInterval)duration {
    %orig(1.0 / getTargetFPS());
}

%end

%hook MTLCommandBuffer

- (void)presentDrawable:(id)drawable afterMinimumDuration:(CFTimeInterval)minimumDuration {
    %orig(drawable, 1.0 / getTargetFPS());
}

%end

%end // Metal group

// #pragma mark - UIKit

// BOOL (*_UIUpdateCycleSchedulerEnabled)(void);

// %group UIKit

// %hookf(BOOL, _UIUpdateCycleSchedulerEnabled) {
//     return YES;
// }

// %end

%ctor {
    loadPreferences();
    if (isTarget(TargetTypeApps) && shouldEnableForBundleIdentifier(NSBundle.mainBundle.bundleIdentifier)) {
        // if (IS_IOS_OR_NEWER(iOS_15_0)) { // iOS 15.0 only?
        //     MSImageRef ref = MSGetImageByName("/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore");
        //     _UIUpdateCycleSchedulerEnabled = (BOOL (*)(void))MSFindSymbol(ref, "__UIUpdateCycleSchedulerEnabled");
        //     if (_UIUpdateCycleSchedulerEnabled) {
        //         %init(UIKit);
        //     }
        // }
        %init;
        if (metalEnabled)
            %init(Metal);
    }
}
