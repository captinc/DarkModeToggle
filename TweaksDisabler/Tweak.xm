//disable tweak injection for certain dylibs. you must put "com.apple.Security" in 001_DarkModeToggleTweaksDisabler.plist for this to work
//also, the dylib that disables tweak injection must be loaded BEFORE the tweaks it disables. do that by making this dylib's name "001_DylibName"
%hookf(void *, dlopen, const char *path, int mode) {
    if (path != NULL) { //you actually need this NULL check
        NSString *dylibPath = [NSString stringWithUTF8String:path];
        NSString *dylibName = [dylibPath.lastPathComponent stringByDeletingPathExtension];
        
        if ([dylibPath containsString:@"/Library/MobileSubstrate/DynamicLibraries"] && ![dylibName isEqualToString:@"DarkModeToggle"]) { //ensure we only affect tweak dylibs so we don't mess with the OS
            NSDictionary *tweakPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist"]; //load prefs
            NSString *state = [tweakPrefs objectForKey:@"darkModeState"];
            NSArray *disabledInDarkMode = [tweakPrefs objectForKey:@"disabledInDarkMode"];
            NSArray *disabledInLightMode = [tweakPrefs objectForKey:@"disabledInLightMode"];
            if (!disabledInDarkMode) {
                disabledInDarkMode = [[NSArray alloc] init];
            }
            if (!disabledInLightMode) {
                disabledInLightMode = [[NSArray alloc] init];
            }
            
            if ([state isEqualToString:@"dark"] && [disabledInDarkMode containsObject:dylibName]) {
                return NULL;
            }
            else if ([state isEqualToString:@"light"] && [disabledInLightMode containsObject:dylibName]) {
                return NULL;
            }
        }
    }
    return %orig;
}
