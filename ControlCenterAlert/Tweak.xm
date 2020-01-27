#import "DarkModeToggleCCAlert.h"

@interface SBHomeScreenViewController : UIViewController
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
@end

@interface CCUIModuleCollectionViewController : UIViewController
- (void)viewDidLoad;
- (void)showDarkModeToggleCCAlert:(NSNotification *)notification;
- (void)showDarkModeToggleCustomModuleError:(NSNotification *)notification;
@end

%hook SBHomeScreenViewController
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection { //this method is called when the user toggles the stock iOS 13 dark mode
    %orig;
    if (@available(iOS 13, *)) {
        NSString *pathToPlistFile = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist"; //load prefs
        NSMutableDictionary *tweakPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:pathToPlistFile];
        if (!tweakPrefs) {
            tweakPrefs = [[NSMutableDictionary alloc] init];
        }
        NSString *ccToggleMode = [tweakPrefs objectForKey:@"ccToggleMode"];
        if (!ccToggleMode) {
            ccToggleMode = @"custom";
        }
        
        if ([ccToggleMode isEqualToString:@"ios13"]) { //only run my code when the user chose "iOS 13 mode" for how to invoke my tweak
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                [tweakPrefs setObject:@"dark" forKey:@"darkModeState"]; //write the current state (dark or light) to my plist so it can be read in other parts of my tweak
                [dict setObject:@"enableDarkMode" forKey:@"changeToMode"];
            }
            else if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                [tweakPrefs setObject:@"light" forKey:@"darkModeState"];
                [dict setObject:@"disableDarkMode" forKey:@"changeToMode"];
            }
            
            [tweakPrefs writeToFile:pathToPlistFile atomically:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"com.captinc.showDarkModeToggleCCAlert" object:nil userInfo:dict]; //obviously, we need to be in one of Control Center's view controllers in order to present a UIAlertController, so post a notification informing Control Center
        }
    }
}
%end

%hook CCUIModuleCollectionViewController
- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDarkModeToggleCCAlert:) name:@"com.captinc.showDarkModeToggleCCAlert" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDarkModeToggleCustomModuleError:) name:@"com.captinc.showDarkModeToggleCustomModuleError" object:nil];
}

%new
- (void)showDarkModeToggleCCAlert:(NSNotification *)notification { //this method is run upon receiving the notification that the user invoked my tweak (this handles invokes from my custom module and the stock dark mode module)
    NSString *changeToMode = [notification.userInfo valueForKey:@"changeToMode"];
    [[DarkModeToggleCCAlert sharedInstance] showAlert:changeToMode CCViewController:self];
}

%new
- (void)showDarkModeToggleCustomModuleError:(NSNotification *)notification {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DarkModeToggle" message:@"Error: in order to use this module, you need to go to Settings > DarkModeToggle and change \"Control center toggle mode\" to \"Custom\"" preferredStyle:UIAlertControllerStyleAlert];
    [[DarkModeToggleCCAlert sharedInstance] makeAlertDarkIfNecessary:alert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}
%end
