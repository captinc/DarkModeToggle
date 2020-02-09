#import "DMTDisabledTweaksBase.h"

@interface DMTDisabledTweaksInLightMode : DMTDisabledTweaksBase
@end

@implementation DMTDisabledTweaksInLightMode
- (NSString *)navBarTitle {
    return @"When in light mode";
}

- (NSString *)keyInPlistFile {
    return @"disabledInLightMode";
}
@end
