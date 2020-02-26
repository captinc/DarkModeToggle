//disable tweak injection for certain dylibs. you must put "com.apple.Security" in 001_DarkModeToggleTweaksDisabler.plist for this to work
//also, the dylib that disables tweak injection must be loaded BEFORE the tweaks it disables. do that by making this dylib's name "001_DylibName"

#import "../Shared.h"

%hookf(void *, dlopen, const char *path, int mode) {
    if (path != NULL) { //must check for null to prevent crashes
        NSString *dylibPath = [NSString stringWithUTF8String:path];
        NSString *dylibName = dylibPath.lastPathComponent.stringByDeletingPathExtension;
        
        if ([dylibPath containsString:@"/Library/MobileSubstrate/DynamicLibraries"]) { //ensure we only affect tweak dylibs so we don't mess with system dylibs
            NSDictionary *tweakPrefs = [NSDictionary dictionaryWithContentsOfFile:plistPath]; //load prefs
            NSString *state = [tweakPrefs objectForKey:@"darkModeState"];
            NSArray *disabledInDarkMode = [tweakPrefs objectForKey:@"disabledInDarkMode"];
            NSArray *disabledInLightMode = [tweakPrefs objectForKey:@"disabledInLightMode"];
            if (!disabledInDarkMode) { //always check if the info we got from the .plist is nil
                disabledInDarkMode = [[NSArray alloc] init];
            }
            if (!disabledInLightMode) {
                disabledInLightMode = [[NSArray alloc] init];
            }
            
            if ([state isEqualToString:@"dark"] && [disabledInDarkMode containsObject:dylibName]) {
                return NULL; //actually disable injection
            }
            else if ([state isEqualToString:@"light"] && [disabledInLightMode containsObject:dylibName]) {
                return NULL;
            }
        }
    }
    return %orig;
}
