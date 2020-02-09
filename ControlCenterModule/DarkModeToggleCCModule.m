#import <ControlCenterUIKit/CCUIToggleModule.h>
#import "../Shared.h"

@interface DarkModeToggleCCModule : CCUIToggleModule {
    BOOL _selected;
}
- (UIImage *)iconGlyph;
- (UIImage *)selectedIconGlyph;
- (UIColor *)selectedColor;
- (BOOL)isSelected;
- (void)setSelected:(BOOL)selected;
@end

@implementation DarkModeToggleCCModule
- (UIImage *)iconGlyph {
    return [UIImage imageNamed:@"ModuleIconLight" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

- (UIImage *)selectedIconGlyph {
    return [UIImage imageNamed:@"ModuleIconDark" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

- (UIColor *)selectedColor {
    return [UIColor blackColor];
}

- (BOOL)isSelected { //other parts of my tweak update whether or not dark mode is on, so this method needs to return YES/NO based on what the plist says
    NSDictionary *tweakPrefs = [NSDictionary dictionaryWithContentsOfFile:plistPath]; //load prefs
    NSString *ccToggleMode = [tweakPrefs objectForKey:@"ccToggleMode"];
    if (!ccToggleMode) {
        ccToggleMode = @"ios13";
    }
    NSString *darkModeState = [tweakPrefs objectForKey:@"darkModeState"]; //no need to check for nil here because this key is not an actual setting that you can change in Settings > DarkModeToggle
    if ([ccToggleMode isEqualToString:@"custom"] && [darkModeState isEqualToString:@"dark"]) { //only make the module selected if the user chose "Custom mode" in my prefs
        return YES;
    }
    return NO;
}

- (void)setSelected:(BOOL)selected {
    NSMutableDictionary *tweakPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (!tweakPrefs) {
        tweakPrefs = [[NSMutableDictionary alloc] init];
    }
    NSString *ccToggleMode = [tweakPrefs objectForKey:@"ccToggleMode"];
    if (!ccToggleMode) {
        ccToggleMode = @"ios13";
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if ([ccToggleMode isEqualToString:@"custom"]) {
        _selected = selected;
        [super refreshState];
        
        if (_selected) {
            [tweakPrefs setObject:@"dark" forKey:@"darkModeState"]; //write the current dark mode state to my plist
            [dict setObject:@"enableDarkMode" forKey:@"changeToMode"]; //pass this string to ControlCenterAlert/Tweak.xm using NSNotification & NSDictionary
        }
        else {
            [tweakPrefs setObject:@"light" forKey:@"darkModeState"];
            [dict setObject:@"disableDarkMode" forKey:@"changeToMode"];
        }
        [tweakPrefs writeToFile:plistPath atomically:YES];
    }
    else { //this means the user tapped my module when they chose "iOS 13 mode" in prefs. obviously that doesn't work
        [dict setObject:@"error" forKey:@"changeToMode"];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.captinc.darkmodetoggle.showCCAlert" object:nil userInfo:dict]; //code is continued in ControlCenterAlert/Tweak.xm
}
@end
