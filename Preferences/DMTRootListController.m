#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface DMTRootListController : PSListController
- (void)viewDidLoad;
- (NSMutableArray *)specifiers;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
@end

@implementation DMTRootListController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"DarkModeToggle";
}

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *pathToPlistFile = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist";
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:pathToPlistFile];
    if (!dict) { //you always need to check if what you got from the plist file is nil and assign it a value if necessary. if you don't do this, you will get unexpected behavior
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict setObject:value forKey:[specifier propertyForKey:@"key"]];
    [dict writeToFile:pathToPlistFile atomically:YES];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *pathToPlistFile = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist";
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:pathToPlistFile];
    id object = [dict objectForKey:[specifier propertyForKey:@"key"]];
    if (!object) {
        object = [specifier propertyForKey:@"default"];
    }
    return object;
}
@end
