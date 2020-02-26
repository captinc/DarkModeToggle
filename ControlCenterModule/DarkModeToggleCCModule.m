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
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath]; //load prefs
    NSString *ccToggleMode = [prefs objectForKey:@"ccToggleMode"];
    if (!ccToggleMode) {
        ccToggleMode = @"ios13";
    }
    NSString *state = [prefs objectForKey:@"darkModeState"]; //no need to check for nil here because this key is not an actual setting that you can change in Settings > DarkModeToggle
    
    if ([ccToggleMode isEqualToString:@"custom"] && [state isEqualToString:@"dark"]) { //only make the module selected if the user chose "Custom mode" in my prefs
        return YES;
    }
    return NO;
}

- (void)setSelected:(BOOL)selected {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (!prefs) {
        prefs = [[NSMutableDictionary alloc] init];
    }
    NSString *ccToggleMode = [prefs objectForKey:@"ccToggleMode"];
    if (!ccToggleMode) {
        ccToggleMode = @"ios13";
    }

    NSString *notificationName;
    if ([ccToggleMode isEqualToString:@"custom"]) {
        _selected = selected;
        [super refreshState];
        
        if (selected) { //write the new state to my plist
            [prefs setObject:@"dark" forKey:@"darkModeState"];
        }
        else {
            [prefs setObject:@"light" forKey:@"darkModeState"];
        }
        [prefs writeToFile:plistPath atomically:YES];
        notificationName = @"com.captinc.darkmodetoggle.updateState"; //post a notification telling my tweak to update itself based on what's in the plist
    }
    else { //this means the user tapped my custom module when they chose "iOS 13 mode" in prefs. obviously that doesn't work
        notificationName = @"com.captinc.darkmodetoggle.showErrorMessage";
    }
    
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:nil];
    //use NSDistributedNotificationCenter instead of NSNotificationCenter so other tweaks can detect when DarkModeToggle is toggled from any process
    //code is continued in SB/Tweak.xm
}
@end
