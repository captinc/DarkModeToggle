#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface DMTDisabledTweaksBase : PSListController {
    NSMutableArray *_tweakChoices;
}
- (NSString *)navBarTitle;
- (NSString *)keyInPlistFile;

- (void)viewDidLoad;
- (NSMutableArray *)specifiers;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
- (void)loadTweakChoices;
- (void)saveTweakChoices;

- (NSArray *)listOfDylibs;
@end
