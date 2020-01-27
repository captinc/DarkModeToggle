#import "DMTTweaksPickerBaseController.h"

@interface DMTDisabledInLightModeController : DMTTweaksPickerBaseController
@end

@implementation DMTDisabledInLightModeController
- (NSString *)navBarTitle {
    return @"When in light mode";
}

- (NSString *)keyInPlistFile {
    return @"disabledInLightMode";
}
@end
//pass that info to the base class so we can have code-reuse and have 2 similar instances of the tweaks-disabler menu
