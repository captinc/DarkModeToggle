#import "DMTPrefsForOtherTweaksBase.h"
#import "../../Shared.h"
//Adding support for a new toggle from another tweak only requires 2 things:
//1. Add an entry in PrefsForOtherTweaks.plist
//2. Add an entry in /ControlCenterAlert/DarkModeToggleCCAlert.xm > "- (NSDictionary *)infoAboutOthers"

@implementation DMTPrefsForOtherTweaksBase
- (NSString *)navBarTitle { //these 2 methods will be overridden in the two subclasses
    return nil;
}

- (NSString *)keyInPlistFile {
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [self navBarTitle];
    
    //hide any specifiers that are not supposed to be visible because the corresponding PSSwitchCell is off. see "- (void)setPreferenceValue:specifier:" down below for more info
    NSDictionary *myTweakPrefs = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSDictionary *prefsForOthers = [myTweakPrefs objectForKey:[self keyInPlistFile]]; //no need to check for nil because this variable is only used to set BOOL isChangingPrefsForTweakEnabled. if a BOOL is nil, it will be "false"
    
    for (PSSpecifier *specifier in _specifiers) {
        NSString *key = [specifier propertyForKey:@"key"];
        BOOL isChangingPrefsForTweakEnabled = [[prefsForOthers objectForKey:key] boolValue];
        
        if ([key containsString:@"-enabled"] && !isChangingPrefsForTweakEnabled) { //see "- (void)setPreferenceValue:specifier:" for an explanation about this weird "-enabled" and "-value" stuff
            NSString *keyForSpecifierToHide = [[key componentsSeparatedByString:@"-"].firstObject stringByAppendingString:@"-value"];
            [self removeContiguousSpecifiers:@[[self.specifiersThatCanHide objectForKey:keyForSpecifierToHide]] animated:YES];
        }
    }
}

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        [self loadPrefs];
        _specifiers = [self loadSpecifiersFromPlistName:@"PrefsForOtherTweaks" target:self];
    }
    
    if (!self.specifiersThatCanHide) {
        self.specifiersThatCanHide = [[NSMutableDictionary alloc] init];
    }
    
    for (PSSpecifier *specifier in _specifiers) { //make a list of all the specifiers that can be hidden when the corresponding PSSwitchCell is turned off
        if ([[specifier propertyForKey:@"key"] containsString:@"-value"]) {
            [self.specifiersThatCanHide setObject:specifier forKey:[specifier propertyForKey:@"key"]];
        }
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    id object = [_prefs objectForKey:[specifier propertyForKey:@"key"]];
    if (!object) { //must check for nil
        object = [specifier propertyForKey:@"default"];
    }
    return object;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    
    //show/hide a specifier when a PSSwitchCell is toggled (similar to Settings > WiFi, where turning the Wifi switch off hides the other visible specifiers)
    //I wanted to make it very easy to add support for more prefs from other tweaks, so I made this -enabled and -value stuff
    //-enabled is the suffix in the "key" property for any PSSwitchCell that enables/disables toggling a pref for another tweak
    //-value is the suffix in the "key" property for any specifier that allows you to choose what value to set when in dark/light mode
    //"-enabled"s show/hide the "-value"s
    if ([key containsString:@"-enabled"]) {
        NSString *keyForSpecifierToHide = [[key componentsSeparatedByString:@"-"].firstObject stringByAppendingString:@"-value"];
        if (![value boolValue]) {
            [self removeContiguousSpecifiers:@[[self.specifiersThatCanHide objectForKey:keyForSpecifierToHide]] animated:YES];
        }
        else {
            [self insertContiguousSpecifiers:@[[self.specifiersThatCanHide objectForKey:keyForSpecifierToHide]] afterSpecifier:specifier animated:YES];
        }
    }
    
    [_prefs setObject:value forKey:key];
    [self savePrefs];
}

- (void)loadPrefs {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSMutableDictionary *prefs = [dict objectForKey:[self keyInPlistFile]];
    if (prefs) {
        _prefs = [prefs mutableCopy];
    }
    else {
        _prefs = [[NSMutableDictionary alloc] init];
    }
}

- (void)savePrefs {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict setObject:[_prefs copy] forKey:[self keyInPlistFile]];
    [dict writeToFile:plistPath atomically:YES];
}
@end
