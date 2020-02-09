#import "DMTDisabledTweaksBase.h"
#import "../../Shared.h"
//we want to make 2 submenus - one for tweaks to disable in dark mode & one for tweaks to disable in light mode
//the submenus would be very similar, so I wanted to have code-reuse
//I do this by making a base class, making two subclasses of it, and then overriding navBarTitle and keyInPlistFile in the subclasses to pass info to the base class

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
        //disallowing Choicy is necessary because:
            //1. Choicy loads before DarkModeToggle and therefore can't be disabled by DarkModeToggle anyway
            //2. this ensures the user can use Choicy to disable DarkModeToggle if necessary
        NSArray *tweaksToNotShow = @[@"001_DarkModeToggleTweaksDisabler", @"DarkModeToggleCCAlert", @"MobileSafety", @"000_Choicy", @"ChoicySB", @"PreferenceLoader"];
        for (NSString *dylib in [self listOfDylibs]) {
            if (![tweaksToNotShow containsObject:dylib]) {
                PSSpecifier *specifierForTweak = [PSSpecifier preferenceSpecifierNamed:dylib target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
                [specifierForTweak setProperty:@YES forKey:@"enabled"];
                [specifierForTweak setProperty:dylib forKey:@"key"];
                [_specifiers addObject:specifierForTweak];
            }
        }
        
        PSSpecifier *footer = [PSSpecifier emptyGroupSpecifier];
        [footer setProperty:@"You can not disable Choicy nor PreferenceLoader due to a compatibility issue" forKey:@"footerText"];
        [_specifiers addObject:footer];
    }
    return _specifiers;
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

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    if ([_tweakChoices containsObject:[specifier propertyForKey:@"key"]]) {
        return @YES;
	}
    return [specifier propertyForKey:@"default"]; //do this instead of "return @NO" so you can turn some toggles on by default if you wish. i don't do that in this tweak, but its useful in other situations
}

- (void)loadTweakChoices {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSArray *array = [dict objectForKey:[self keyInPlistFile]];
    if (array) { //remember: always check if what you got from the plist file is nil to avoid unwanted behavior
        _tweakChoices = [array mutableCopy];
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
        if (![item.pathExtension isEqualToString:@"plist"] && [item checkResourceIsReachableAndReturnError:nil]) {
            [dylibs addObject:[item.path.lastPathComponent stringByDeletingPathExtension]];
        }
    }
    
    return [[dylibs copy] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}
@end
