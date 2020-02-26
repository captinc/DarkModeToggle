#import <Preferences/PSViewController.h>
#import "DMTPrefsForOtherTweaksAll.h"

@interface DMTSnowBoardPrefs : PSViewController <UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *_availableThemes;
    NSMutableArray *_enabledThemes;
}
@property NSString *navBarTitle;
@property NSString *keyInPlistFile;
@property DMTPrefsForOtherTweaksBase *previousVC;
@property UITableView *tableView;
- (instancetype)initWithTitle:(NSString *)title plistKey:(NSString *)plistKey sendingViewController:(DMTPrefsForOtherTweaksBase *)sender;
- (void)viewDidLoad;
- (void)createTableView;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

- (void)loadAvailableThemes;
- (void)loadEnabledThemes;
- (void)saveEnabledThemes;
@end
