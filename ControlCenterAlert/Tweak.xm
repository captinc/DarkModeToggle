#import "DarkModeToggleCCAlert.h"
#import "../Shared.h"

@interface SBHomeScreenViewController : UIViewController
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
@end

@interface CCUIModuleCollectionViewController : UIViewController
- (void)viewDidLoad;
- (void)dealloc;
- (void)darkModeToggleShowCCAlert:(NSNotification *)notification;
@end

%hook SBHomeScreenViewController
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection { //this method is called when iOS 13's dark mode is toggled
    %orig;
    if (@available(iOS 13, *)) {
        NSMutableDictionary *tweakPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath]; //load prefs
        if (!tweakPrefs) {
            tweakPrefs = [[NSMutableDictionary alloc] init];
        }
        NSString *ccToggleMode = [tweakPrefs objectForKey:@"ccToggleMode"];
        if (!ccToggleMode) {
            ccToggleMode = @"ios13";
        }
        
        if ([ccToggleMode isEqualToString:@"ios13"]) { //only run this hook if the user chose "iOS 13 mode" in my prefs
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                [tweakPrefs setObject:@"dark" forKey:@"darkModeState"]; //write the current state (dark or light) to my plist so it can be read in other parts of my tweak
                [dict setObject:@"enableDarkMode" forKey:@"changeToMode"];
            }
            else if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                [tweakPrefs setObject:@"light" forKey:@"darkModeState"];
                [dict setObject:@"disableDarkMode" forKey:@"changeToMode"];
            }
            [tweakPrefs writeToFile:plistPath atomically:YES];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"com.captinc.darkmodetoggle.showCCAlert" object:nil userInfo:dict]; //to show a UIAlertController on top of Control Center, we need to be in one of CC's view controllers (which are are not). so, post a notification telling CC to show the UIAlertController
        }
    }
}
%end

%hook CCUIModuleCollectionViewController
- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkModeToggleShowCCAlert:) name:@"com.captinc.darkmodetoggle.showCCAlert" object:nil];
}

- (void)dealloc {
    %orig;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
%new
- (void)darkModeToggleShowCCAlert:(NSNotification *)notification { //this method is run upon receiving the notification that the user invoked my tweak from either the stock dark mode module or my custom module
    DarkModeToggleCCAlert *dmt = [DarkModeToggleCCAlert sharedInstance];
    NSString *changeToMode = [notification.userInfo valueForKey:@"changeToMode"];
    
    if ([changeToMode isEqualToString:@"error"]) { //this means the user tapped my custom module when they chose "iOS 13 mode" in prefs
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DarkModeToggle" message:@"Error: in order to use this module, you need to go to Settings > DarkModeToggle and change \"Control center toggle mode\" to \"Custom\"" preferredStyle:UIAlertControllerStyleAlert];
        [dmt makeAlertDarkIfNecessary:alert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        [dmt updatePrefsForOtherTweaks:changeToMode]; //if necessary, change the preferences for other tweaks
        [dmt showAlert:changeToMode CCViewController:self];
    }
}
%end
