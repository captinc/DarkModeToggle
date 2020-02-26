#import "DMTRootListController.h"
#import "../Shared.h"

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

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    id object = [dict objectForKey:[specifier propertyForKey:@"key"]];
    if (!object) { //you always need to check if what you got from the plist file is nil and assign it a value if necessary. if you don't do this, you will get unexpected behavior
        object = [specifier propertyForKey:@"default"];
    }
    return object;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict setObject:value forKey:[specifier propertyForKey:@"key"]];
    [dict writeToFile:plistPath atomically:YES];
}

- (void)didTapHelpButton {
    NSDictionary *options = @{UIApplicationOpenURLOptionUniversalLinksOnly:@NO};
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/jailbreak/comments/euiss0/release_darkmodetoggle_enabledisable_specific"] options:options completionHandler:nil];
}
@end
