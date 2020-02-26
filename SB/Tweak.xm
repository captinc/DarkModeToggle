#import "DarkModeToggleSB.h"
#import "../Shared.h"

@interface SBHomeScreenViewController : UIViewController
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
@end

@interface CCUIModuleCollectionViewController : UIViewController
- (void)viewDidLoad;
- (void)dealloc;
- (void)startDarkModeToggle;
- (void)darkModeToggleShowErrorMessage;
@end

%hook SBHomeScreenViewController
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection { //this method is called when iOS 13's dark mode is toggled
    %orig;
    if (@available(iOS 13, *)) {
        NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath]; //load prefs
        if (!prefs) {
            prefs = [[NSMutableDictionary alloc] init];
        }
        NSString *ccToggleMode = [prefs objectForKey:@"ccToggleMode"];
        if (!ccToggleMode) {
            ccToggleMode = @"ios13";
        }
        
        if ([ccToggleMode isEqualToString:@"ios13"]) { //only run this hook if the user chose "iOS 13 mode" in my prefs
            if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) { //write the new state to my plist
                [prefs setObject:@"dark" forKey:@"darkModeState"];
                
            }
            else if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                [prefs setObject:@"light" forKey:@"darkModeState"];
            }
            [prefs writeToFile:plistPath atomically:YES];
            
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.captinc.darkmodetoggle.updateState" object:nil userInfo:nil]; //post a notification telling my tweak to update itself based on what's in the plist
            //use NSDistributedNotificationCenter instead of NSNotificationCenter so other tweaks can detect when DarkModeToggle is toggled from any process
        }
    }
}
%end

%hook CCUIModuleCollectionViewController
- (void)viewDidLoad {
    %orig;
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(startDarkModeToggle) name:@"com.captinc.darkmodetoggle.updateState" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(darkModeToggleShowErrorMessage) name:@"com.captinc.darkmodetoggle.showErrorMessage" object:nil];
}

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}
%new
- (void)startDarkModeToggle { //this method is run upon receiving the notification that the user toggled dark mode from either the stock module or my custom module
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath]; //now that my tweak has been toggled, determine its current state
    NSString *state = [prefs objectForKey:@"darkModeState"];
    NSString *changeToMode;
    if ([state isEqualToString:@"dark"]) {
        changeToMode = @"enable";
    }
    else if ([state isEqualToString:@"light"]) {
        changeToMode = @"disable";
    }
    
    DarkModeToggleSB *dmt = [DarkModeToggleSB sharedInstance];
    [dmt updatePrefsForOtherTweaks:changeToMode]; //if necessary, change the preferences for other tweaks
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.captinc.darkmodetoggle.stateChanged" object:nil userInfo:nil]; //notify other tweaks that DarkModeToggle finished toggling
    [dmt showAlert:changeToMode CCViewController:self];
}
%new
- (void)darkModeToggleShowErrorMessage { //this means the user tapped my custom module when they chose "iOS 13 mode" in prefs. obviously that doesn't work
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DarkModeToggle" message:@"Error: in order to use this module, you need to go to Settings > DarkModeToggle and change \"Control center toggle mode\" to \"Custom\"" preferredStyle:UIAlertControllerStyleAlert];
    [[DarkModeToggleSB sharedInstance] makeAlertDarkIfNecessary:alert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}
%end
