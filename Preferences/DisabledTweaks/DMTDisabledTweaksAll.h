#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface DMTDisabledTweaksBase : PSListController {
    NSMutableArray *_tweakChoices;
}
- (NSString *)navBarTitle;
- (NSString *)keyInPlistFile;
- (void)viewDidLoad;

- (NSMutableArray *)specifiers;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
- (void)loadTweakChoices;
- (void)saveTweakChoices;

- (NSArray *)listOfDylibs;
@end

@interface DMTDisabledTweaksInDarkMode : DMTDisabledTweaksBase
- (NSString *)navBarTitle;
- (NSString *)keyInPlistFile;
@end

@interface DMTDisabledTweaksInLightMode : DMTDisabledTweaksBase
- (NSString *)navBarTitle;
- (NSString *)keyInPlistFile;
@end
