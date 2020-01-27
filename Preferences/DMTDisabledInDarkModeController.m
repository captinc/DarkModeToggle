#import "DMTTweaksPickerBaseController.h"

@interface DMTDisabledInDarkModeController : DMTTweaksPickerBaseController
@end

@implementation DMTDisabledInDarkModeController
- (NSString *)navBarTitle {
    return @"When in dark mode";
}

- (NSString *)keyInPlistFile {
    return @"disabledInDarkMode";
}
@end
