//we want to make 2 submenus - one for tweaks to disable in dark mode & one for tweaks to disable in light mode
//the submenus would be very similar, so I wanted to have code-reuse
//I do this by making a base class, making two subclasses of it, and then overriding navBarTitle and keyInPlistFile in the subclasses to pass info to the base class

#import "DMTDisabledTweaksAll.h"
#import "../../Shared.h"

@implementation DMTDisabledTweaksBase
- (NSString *)navBarTitle {
    return nil;
}

- (NSString *)keyInPlistFile {
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [self navBarTitle];
}

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        [self loadTweakChoices];
        _specifiers = [[NSMutableArray alloc] init];
        [_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"Disable these tweaks"]]; //section title/header
        
        //do not allow disabling MobileSafety and PreferenceLoader because that's just asking for trouble
        //disallowing disabling other tweak disablers is a good idea so users can disable DarkModeToggle if necessary
        NSArray *tweaksToNotShow = @[@"001_DarkModeToggleTweaksDisabler", @"DarkModeToggleSB", @"MobileSafety", @"PreferenceLoader", @"000_Choicy", @"ChoicySB", @" TweakConfigurator", @"TweakRestrictor", @"zzzzzzUnSub", @"NoSubstitute", @"NoSubstitute12", @"PalBreakSB"];
        for (NSString *dylib in [self listOfDylibs]) {
            if (![tweaksToNotShow containsObject:dylib]) {
                PSSpecifier *specifierForTheme = [PSSpecifier preferenceSpecifierNamed:dylib target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
                [specifierForTheme setProperty:@YES forKey:@"enabled"];
                [specifierForTheme setProperty:dylib forKey:@"key"];
                [_specifiers addObject:specifierForTheme];
            }
        }
        
        PSSpecifier *footer = [PSSpecifier emptyGroupSpecifier];
        NSString *msg = @"Due to a compatibility issue, you cannot disable PreferenceLoader, Choicy, NoSubstitute, NoSubstitute12, NoSub (PalBreak w/ options), TweakConfigurator, TweakRestrictor, and UnSub";
        [footer setProperty:msg forKey:@"footerText"];
        [_specifiers addObject:footer];
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    if ([_tweakChoices containsObject:[specifier propertyForKey:@"key"]]) {
        return @YES;
    }
    return [specifier propertyForKey:@"default"]; //do this instead of "return @NO" so you can turn some toggles on by default if you wish. i don't do that in this tweak, but its useful in other situations
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSNumber *val = value;
    if (val.boolValue) {
        [_tweakChoices addObject:[specifier propertyForKey:@"key"]];
	}
	else {
		[_tweakChoices removeObject:[specifier propertyForKey:@"key"]];
	}
    [self saveTweakChoices];
}

- (void)loadTweakChoices {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSArray *tweakChoicesInPlist = [dict objectForKey:[self keyInPlistFile]];
    if (tweakChoicesInPlist) { //remember: always check if what you got from the plist file is nil to avoid unwanted behavior
        _tweakChoices = [tweakChoicesInPlist mutableCopy];
    }
    else {
        _tweakChoices = [[NSMutableArray alloc] init];
    }
}

- (void)saveTweakChoices {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
	if (!dict) {
		dict = [[NSMutableDictionary alloc] init];
	}
    [dict setObject:[_tweakChoices copy] forKey:[self keyInPlistFile]];
	[dict writeToFile:plistPath atomically:YES];
}

- (NSArray *)listOfDylibs { //creates an array of all tweak dylibs so we can choose which ones to disable
    NSURL *pathToDylibsFolder = [NSURL fileURLWithPath:@"/Library/MobileSubstrate/DynamicLibraries"].URLByResolvingSymlinksInPath;
    NSArray *folderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:pathToDylibsFolder includingPropertiesForKeys:nil options:0 error:nil];
    
    NSMutableArray *dylibs = [[NSMutableArray alloc] init];
    for (NSURL *item in folderContents) {
        if ([item.pathExtension isEqualToString:@"dylib"] && [item checkResourceIsReachableAndReturnError:nil]) {
            [dylibs addObject:item.path.lastPathComponent.stringByDeletingPathExtension];
        }
    }
    
    return [[dylibs copy] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}
@end
