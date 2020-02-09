#import "DMTPrefsForOtherTweaksBase.h"

@interface DMTPrefsForOtherTweaksInLightMode : DMTPrefsForOtherTweaksBase
@end

@implementation DMTPrefsForOtherTweaksInLightMode
- (NSString *)navBarTitle {
    return @"When in light mode";
}

- (NSString *)keyInPlistFile {
    return @"prefsForOthersInLightMode";
}
@end
