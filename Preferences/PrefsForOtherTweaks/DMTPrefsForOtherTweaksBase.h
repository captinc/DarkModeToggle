#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface DMTPrefsForOtherTweaksBase : PSListController {
    NSMutableDictionary *_prefs;
}
@property NSMutableDictionary *specifiersThatCanHide;
- (NSString *)navBarTitle;
- (NSString *)keyInPlistFile;

- (void)viewDidLoad;
- (NSMutableArray *)specifiers;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
- (void)loadPrefs;
- (void)savePrefs;
@end
