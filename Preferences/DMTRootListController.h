#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface DMTRootListController : PSListController
- (void)viewDidLoad;
- (NSMutableArray *)specifiers;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
- (void)didTapHelpButton;
@end
