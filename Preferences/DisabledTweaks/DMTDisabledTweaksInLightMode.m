#import "DMTDisabledTweaksAll.h"

@implementation DMTDisabledTweaksInLightMode
- (NSString *)navBarTitle {
    return @"When in light mode";
}

- (NSString *)keyInPlistFile {
    return @"disabledInLightMode";
}
@end
