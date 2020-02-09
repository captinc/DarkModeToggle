#import "DMTPrefsForOtherTweaksBase.h"

@interface DMTPrefsForOtherTweaksInDarkMode : DMTPrefsForOtherTweaksBase
@end

@implementation DMTPrefsForOtherTweaksInDarkMode
- (NSString *)navBarTitle {
    return @"When in dark mode";
}

- (NSString *)keyInPlistFile {
    return @"prefsForOthersInDarkMode";
}
@end
