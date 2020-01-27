#import <ControlCenterUIKit/CCUIToggleModule.h>

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

- (BOOL)isSelected { //other parts of my tweak update whether or not dark mode is on, so we need to make my custom module selected based on what the plist says
    NSString *pathToPlistFile = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist";
    NSDictionary *tweakPrefs = [NSDictionary dictionaryWithContentsOfFile:pathToPlistFile];
    NSString *ccToggleMode = [tweakPrefs objectForKey:@"ccToggleMode"];
    NSString *darkModeState = [tweakPrefs objectForKey:@"darkModeState"];
    if ([ccToggleMode isEqualToString:@"custom"] && [darkModeState isEqualToString:@"dark"]) { //only make the module selected if the user chose "Custom mode" in prefs
        return YES;
    }
    return NO;
}

- (void)setSelected:(BOOL)selected {
    NSString *pathToPlistFile = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist"; //load prefs
    NSMutableDictionary *tweakPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:pathToPlistFile];
    if (!tweakPrefs) {
        tweakPrefs = [[NSMutableDictionary alloc] init];
    }
    NSString *ccToggleMode = [tweakPrefs objectForKey:@"ccToggleMode"];
    if (!ccToggleMode) {
        ccToggleMode = @"ios13";
    }
    
    if ([ccToggleMode isEqualToString:@"custom"]) {
        _selected = selected;
        [super refreshState];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        if (_selected) {
            [tweakPrefs setObject:@"dark" forKey:@"darkModeState"]; //write the current dark mode state to my plist
            [dict setObject:@"enableDarkMode" forKey:@"changeToMode"]; //pass this string to ControlCenterAlert/Tweak.xm using NSNotification & NSDictionary
        }
        else {
            [tweakPrefs setObject:@"light" forKey:@"darkModeState"];
            [dict setObject:@"disableDarkMode" forKey:@"changeToMode"];
        }
        
        [tweakPrefs writeToFile:pathToPlistFile atomically:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.captinc.showDarkModeToggleCCAlert" object:nil userInfo:dict];
    }
    else { //this means the user tapped my module when they chose to user "iOS 13 mode" in prefs. obviously that doesn't work. code is continued in ControlCenterAlert/Tweak.xm
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.captinc.showDarkModeToggleCustomModuleError" object:nil userInfo:nil];
    }
}
@end
