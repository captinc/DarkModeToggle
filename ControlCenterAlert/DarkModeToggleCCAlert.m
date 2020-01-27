#import "DarkModeToggleCCAlert.h"
#import "../NSTask.h"

@implementation DarkModeToggleCCAlert
+ (instancetype)sharedInstance {
    static DarkModeToggleCCAlert *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (void)makeAlertDarkIfNecessary:(UIAlertController *)alert { //for some reason, Control Center does not respect the iOS 13 dark mode, so I have to manually make my alerts dark if we are in dark mode
    if (@available(iOS 13, *)) {
        NSDictionary *tweakPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist"];
        NSString *darkModeState = [tweakPrefs objectForKey:@"darkModeState"];
        if (!darkModeState) {
            darkModeState = @"light";
        }
        if ([darkModeState isEqualToString:@"dark"]) {
            alert.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }
    }
}

- (void)addButtonsToAlert:(UIAlertController *)alert {
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self respring];
    }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    [alert addAction:yesAction];
    [alert addAction:noAction];
}

- (void)showAlert:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC { //shows the UIAlertController you see in Control Center when using my tweak
    NSDictionary *tweakPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist"]; //load my tweak's preferences
    NSString *respringMode = [tweakPrefs objectForKey:@"respringMode"];
    if (!respringMode) {
        respringMode = @"ask";
    }
    BOOL shouldRunScript = [[tweakPrefs objectForKey:@"runScripts"] boolValue];
    
    if ([respringMode isEqualToString:@"none"]) { //if the user chose "None" for the respring prefs
        if (shouldRunScript) {
            [self runScript:changeToMode CCViewController:CCVC askToRespring:false respringImmediately:false message:@"Running script...."];
        }
    }
    else if ([respringMode isEqualToString:@"ask"]) { //"Ask to respring"
        if (shouldRunScript) {
            [self runScript:changeToMode CCViewController:CCVC askToRespring:true respringImmediately:false message:@"Running script...."];
        }
        else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DarkModeToggle" message:@"Respring?" preferredStyle:UIAlertControllerStyleAlert];
            [self makeAlertDarkIfNecessary:alert];
            [self addButtonsToAlert:alert];
            [CCVC presentViewController:alert animated:YES completion:nil];
        }
    }
    else { //"Auto respring"
        if (shouldRunScript) {
            [self runScript:changeToMode CCViewController:CCVC askToRespring:false respringImmediately:true message:@"Running script and respringing...."];
        }
        else {
            [self respring];
        }
    }
}

- (void)runScript:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC askToRespring:(bool)askToRespring respringImmediately:(bool)respringImmediately message:(NSString *)msg  { //shows a processing screen & then runs the extension scripts as root
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DarkModeToggle" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [self makeAlertDarkIfNecessary:alert];
    [CCVC presentViewController:alert animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) { //must dispatch_async so the UI doesn't freeze while the script is running
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = @"/usr/bin/darkmodetoggled";
            task.arguments = @[changeToMode];
            [task launch];
            [task waitUntilExit];
            
            dispatch_sync(dispatch_get_main_queue(), ^{ //once the script is finished, update the UI
                if (askToRespring) {
                    [UIView transitionWithView:alert.view duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) {
                        alert.message = @"Done! Respring?";
                    } completion:nil];
                    [self addButtonsToAlert:alert];
                }
                else if (respringImmediately) {
                    [self respring];
                }
                else {
                    [alert dismissViewControllerAnimated:YES completion:nil];
                }
            });
        });
    }];
}

- (void)respring {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/sbreload";
    [task launch];
    [task waitUntilExit];
}
@end
