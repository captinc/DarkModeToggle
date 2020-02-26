#import "DMTDisabledTweaksAll.h"

@implementation DMTDisabledTweaksInDarkMode
- (NSString *)navBarTitle {
    return @"When in dark mode";
}

- (NSString *)keyInPlistFile {
    return @"disabledInDarkMode";
}
@end
//subclassing allows me to pass info to the base class. this means we can do code-reuse and have 2 similar instances of the tweaks-disabler menu
