#import "DMTDisabledTweaksBase.h"

@interface DMTDisabledTweaksInDarkMode : DMTDisabledTweaksBase
@end

@implementation DMTDisabledTweaksInDarkMode //subclassing allows me to pass info to the base class. this means we can have code-reuse and have 2 similar instances of the tweaks-disabler menu
- (NSString *)navBarTitle {
    return @"When in dark mode";
}

- (NSString *)keyInPlistFile {
    return @"disabledInDarkMode";
}
@end
