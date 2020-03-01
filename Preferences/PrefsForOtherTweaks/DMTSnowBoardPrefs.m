#import "DMTSnowBoardPrefs.h"
#import "../../Shared.h"

@implementation DMTSnowBoardPrefs
- (instancetype)initWithTitle:(NSString *)title plistKey:(NSString *)plistKey sendingViewController:(DMTPrefsForOtherTweaksBase *)sender {
    self = [super init];
    self.navBarTitle = title; //acquire some info from the sending PrefsForOtherTweaks class
    self.keyInPlistFile = plistKey;
    self.previousVC = sender;
    [self loadAvailableThemes];
    [self loadEnabledThemes];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = self.navBarTitle;
    [self createTableView];
}

- (void)createTableView {
    CGRect frame = self.previousVC.view.frame;
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [tableView registerClass:[UITableViewCell self] forCellReuseIdentifier:@"Cell"];
    tableView.delegate = self;
    tableView.dataSource = self;
    
    //I want to re-order the cells in this UITableView, but in order to do that, I have to create my own view controller (cannot subclass the stock Settings.app VCs)
    //but I also want my VC to look like Settings's stock VCs
    tableView.backgroundColor = self.previousVC.view.backgroundColor; //match my background color to the stock color
    
    [tableView setEditing:YES animated:YES]; //automatically enter tableview edit mode upon opening my VC
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [_enabledThemes count];
    }
    return [_availableThemes count];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { //add section separators and hide the cell separator lines of extraneous/unused cells
    return [[UIView alloc] init];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { //create one tableview section that has the green "plus" icon and another with the red "minus" icon
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleDelete;
    }
    else {
        return UITableViewCellEditingStyleInsert;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath { //only allow cells in the top section to be re-organized
    if (indexPath.section == 0) {
        return YES;
    }
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath { //disallow moving cells into the bottom section (must tap the red "minus" icon instead)
    if (proposedDestinationIndexPath.section == 1) {
        return sourceIndexPath;
    }
    return proposedDestinationIndexPath;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.showsReorderControl = YES; //needed for reorganizing the order of tableview cells
    }
    
    //match each cell's background color to the stock Settings.app color
    NSMutableDictionary *manyStockCells = [self.previousVC valueForKey:@"_cells"];
    id key = [[manyStockCells allKeys] objectAtIndex:0];
    UITableViewCell *oneStockCell = [manyStockCells objectForKey:key];
    cell.backgroundColor = oneStockCell.backgroundColor;
    
    NSString *pathToTheme;
    if (indexPath.section == 0) {
        pathToTheme = [_enabledThemes objectAtIndex:indexPath.row];
    }
    else {
        pathToTheme = [_availableThemes objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = pathToTheme.lastPathComponent.stringByDeletingPathExtension;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath { //upon tapping the green plus/red minus icons
    NSString *themeToMove; //determine what theme/cell to move
    if (indexPath.section == 0) {
        themeToMove = [_enabledThemes objectAtIndex:indexPath.row];
    }
    else {
        themeToMove = [_availableThemes objectAtIndex:indexPath.row];
    }
    
    //move the cell to the opposite section
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_enabledThemes removeObjectAtIndex:indexPath.row];
        [_availableThemes insertObject:themeToMove atIndex:0];
        [_availableThemes sortUsingSelector:@selector(caseInsensitiveCompare:)]; //make the second section always stay alphabetized, even after moving a cell into it
        int insertionIndex = [_availableThemes indexOfObject:themeToMove];
        [tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:insertionIndex inSection:1]];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        int insertionIndex = [_enabledThemes count]; //when moving cells into the first section, place them at the bottom of the first section
        [_availableThemes removeObjectAtIndex:indexPath.row];
        [_enabledThemes insertObject:themeToMove atIndex:insertionIndex];
        [tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:insertionIndex inSection:0]];
    }
    [self saveEnabledThemes];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath { //reorganizing the order of tableview cells
    if (sourceIndexPath != destinationIndexPath) {
        NSString *themeToMove = [_enabledThemes objectAtIndex:sourceIndexPath.row];
        [_enabledThemes removeObjectAtIndex:sourceIndexPath.row];
        [_enabledThemes insertObject:themeToMove atIndex:destinationIndexPath.row];
        [tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
        [self saveEnabledThemes];
    }
}

- (void)loadAvailableThemes { //load a list of all currently-installed themes
    NSURL *pathToThemesFolder = [NSURL fileURLWithPath:@"/Library/Themes"].URLByResolvingSymlinksInPath;
    NSArray *folderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:pathToThemesFolder includingPropertiesForKeys:nil options:0 error:nil];
    
    _availableThemes = [[NSMutableArray alloc] init];
    for (NSURL *item in folderContents) {
        if ([item checkResourceIsReachableAndReturnError:nil]) {
            [_availableThemes addObject:item.path];
        }
    }
    
    [_availableThemes sortUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void)loadEnabledThemes { //from my plist, load the list of themes that the user chose
    NSDictionary *rootDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSDictionary *prefsForOthersDict = [rootDict objectForKey:self.keyInPlistFile];
    NSArray *enabledThemesInPlist = [prefsForOthersDict objectForKey:@"snowBoard-value"];
    if (enabledThemesInPlist) { //remember: always check if what you got from the plist file is nil to avoid unwanted behavior
        _enabledThemes = [enabledThemesInPlist mutableCopy];
    }
    else {
        _enabledThemes = [[NSMutableArray alloc] init];
    }
    
    for (NSString *theme in _enabledThemes) {
        if ([_availableThemes containsObject:theme]) {
            [_availableThemes removeObject:theme];
        }
    }
}

- (void)saveEnabledThemes { //write updated prefs to my plist
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (!rootDict) {
        rootDict = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *prefsForOthersDict = [rootDict objectForKey:self.keyInPlistFile];
    if (!prefsForOthersDict) {
        prefsForOthersDict = [[NSMutableDictionary alloc] init];
    }
    
    [prefsForOthersDict setObject:[_enabledThemes copy] forKey:@"snowBoard-value"];
    [rootDict setObject:prefsForOthersDict forKey:self.keyInPlistFile];
    [rootDict writeToFile:plistPath atomically:YES];
}
@end
