#import "DarkModeToggleCCAlert.h"
#import "../Shared.h"
#import "../NSTask.h"
//Adding support for a new toggle from another tweak only requires 2 things:
//1. Add an entry in PrefsForOtherTweaks.plist
//2. Add an entry in "- (NSDictionary *)infoAboutOthers"

@implementation DarkModeToggleCCAlert
+ (instancetype)sharedInstance {
    static DarkModeToggleCCAlert *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (void)showAlert:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC { //shows the UIAlertController you see in Control Center when using my tweak
    NSDictionary *tweakPrefs = [NSDictionary dictionaryWithContentsOfFile:plistPath]; //load prefs
    NSString *respringMode = [tweakPrefs objectForKey:@"respringMode"];
    if (!respringMode) {
        respringMode = @"ask";
    }
    BOOL shouldRunScript = [[tweakPrefs objectForKey:@"runScripts"] boolValue];
    
    if ([respringMode isEqualToString:@"none"]) { //if the user chose "None" for "Respring mode" in prefs
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

- (void)runScript:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC askToRespring:(bool)askToRespring respringImmediately:(bool)respringImmediately message:(NSString *)msg  { //shows a processing screen & then runs the corresponding script as root
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DarkModeToggle" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [self makeAlertDarkIfNecessary:alert];
    
    [CCVC presentViewController:alert animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) { //must dispatch_async so the UI doesn't freeze while the script is running
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = @"/usr/bin/darkmodetoggled"; //in order to run the script as root, we have to call darkmodetoggled (cannot directly call the script)
            task.arguments = @[changeToMode];
            [task launch];
            [task waitUntilExit];
            
            dispatch_sync(dispatch_get_main_queue(), ^{ //when finished, update the UI
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

- (void)makeAlertDarkIfNecessary:(UIAlertController *)alert { //for some reason, Control Center does not update its UITraitCollection with iOS 13's dark mode, so I have to manually make my alert dark if necessary
    if (@available(iOS 13, *)) {
        UIWindow *sb;
        NSArray *windows = [(UIApplication *)[[UIApplication sharedApplication] delegate] windows];
        for (UIWindow *win in windows) {
            if ([win isKindOfClass:%c(SBHomeScreenWindow)]) {
                sb = win;
                break;
            }
        }
        
        if (sb.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            alert.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }
    }
}

- (void)addButtonsToAlert:(UIAlertController *)alert {
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self respring];
    }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:yesAction];
    [alert addAction:noAction];
}

- (void)updatePrefsForOtherTweaks:(NSString *)changeToMode { //updates prefs any tweaks that the uesr chose in "Settings > DarkModeToggle > Apply these preferences to other tweaks"
    NSString *prefsKeyForCurrentState; //determine if we just enabled or disabled dark mode and set these variables accordingly so they will access the correct info from my .plist
    NSString *defaultValueForCurrentState;
    if ([changeToMode isEqualToString:@"enableDarkMode"]) {
        prefsKeyForCurrentState = @"prefsForOthersInDarkMode";
        defaultValueForCurrentState = @"defaultValueWhenDark";
    }
    else {
        prefsKeyForCurrentState = @"prefsForOthersInLightMode";
        defaultValueForCurrentState = @"defaultValueWhenLight";
    }
    
    NSDictionary *tweakPrefs = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSDictionary *prefsForOthers = [tweakPrefs objectForKey:prefsKeyForCurrentState];
    if (!prefsForOthers) {
        prefsForOthers = [[NSDictionary alloc] init];
    }
    NSDictionary *infoAboutOthers = [self infoAboutOthers];
    
    for (NSString *tweak in infoAboutOthers) {
        NSString *keyForIsChangingPrefsEnabled = [tweak stringByAppendingString:@"-enabled"];
        if ([prefsForOthers objectForKey:keyForIsChangingPrefsEnabled]) { //if the enabled switch is on for the tweak referenced in this loop iteration
            NSDictionary *infoAboutTweak = [infoAboutOthers objectForKey:tweak]; //load information for the tweak handled in this loop iteration
            NSString *keyInOtherPref = [infoAboutTweak objectForKey:@"keyInOtherPref"];
            NSString *keyType = [infoAboutTweak objectForKey:@"keyType"];
            NSString *keyForValueInCurrentState = [tweak stringByAppendingString:@"-value"]; //load the wanted value for the current dark mode state
            NSString *valueInCurrentState = [prefsForOthers objectForKey:keyForValueInCurrentState];
            if (!valueInCurrentState) { //always check if what we got from the .plist is nil and handle accordingly
                valueInCurrentState = [infoAboutTweak objectForKey:defaultValueForCurrentState];
            }
            NSString *plistName = [infoAboutTweak objectForKey:@"plistName"];
            CFStringRef notificationName = (__bridge CFStringRef)[infoAboutTweak objectForKey:@"notificationName"]; //see below for an explanation about this
            
            CFPropertyListRef valueToSetForCFMode; //convert the wanted value to the appropriate data type for use with either the CF method or NS method (explanation below)
            id valueToSetForNSMode;
            if ([keyType isEqualToString:@"string"]) {
                valueToSetForCFMode = (__bridge CFPropertyListRef)valueInCurrentState;
                valueToSetForNSMode = valueInCurrentState;
            }
            else if ([keyType isEqualToString:@"number"]) {
                int num = [valueInCurrentState intValue];
                valueToSetForCFMode = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberIntType, &num);
                valueToSetForNSMode = [[[NSNumberFormatter alloc] init] numberFromString:valueInCurrentState];
            }
            else if ([keyType isEqualToString:@"bool"]) {
                valueToSetForCFMode = (__bridge CFPropertyListRef)[NSNumber numberWithBool:[valueInCurrentState boolValue]];
                valueToSetForNSMode = [NSNumber numberWithBool:[valueInCurrentState boolValue]];
            }
            
            //actually set the pref value for the other tweak
            //for some reason, setting prefs via CFPreferencesSetAppValue() works for somet tweaks but not others. the same is true for using NSMutableDictionary and writeToFile:atomically:
            //so, we have to specify which method to use for each supported tweak
            if ([[infoAboutTweak objectForKey:@"mode"] isEqualToString:@"CF"]) {
                CFPreferencesSetAppValue((__bridge CFStringRef)keyInOtherPref, valueToSetForCFMode, (__bridge CFStringRef)plistName);
            }
            else {
                NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@%@", plistName, @".plist"];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
                if (!dict) {
                    dict = [[NSMutableDictionary alloc] init];
                }
                [dict setObject:valueToSetForNSMode forKey:keyInOtherPref];
                [dict writeToFile:path atomically:YES];
            }
            
            //if necessary, post a notification telling that tweak to update its prefs
            //must use CFNotificationCenter instead of NSNotificationCenter because this notification needs to be global/cross between processes
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, nil, nil, true);
        }
    }
}

- (NSDictionary *)infoAboutOthers { //a list of necessary information for changing prefs of another tweak
    return @{
            @"callBarXS":@{
                    @"keyInOtherPref":@"viewStyle",
                    @"keyType":@"number",
                    @"mode":@"CF",
                    @"defaultValueWhenDark":@"5",
                    @"defaultValueWhenLight":@"4",
                    @"plistName":@"net.limneos.callbarx",
                    @"notificationName":@"net.limneos.callbarx.settingsChanged"},
            
            @"complications":@{
                    @"keyInOtherPref":@"backgroundStyle",
                    @"keyType":@"string",
                    @"mode":@"CF",
                    @"defaultValueWhenDark":@"Dark",
                    @"defaultValueWhenLight":@"Light",
                    @"plistName":@"com.bengiannis.complicationsprefs",
                    @"notificationName":@"com.captinc.darkmodetoggle.null"},
            
            @"grupi":@{
                    @"keyInOtherPref":@"CellStyle",
                    @"keyType":@"number",
                    @"mode":@"CF",
                    @"defaultValueWhenDark":@"1",
                    @"defaultValueWhenLight":@"0",
                    @"plistName":@"com.peterdev.grupi",
                    @"notificationName":@"com.peterdev.grupi/ReloadPrefs"},
            
            @"mot":@{
                    @"keyInOtherPref":@"isDarkModeEnabled",
                    @"keyType":@"bool",
                    @"mode":@"CF",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"plistName":@"com.donbytyqi.mot",
                    @"notificationName":@"com.donbytyqi.mot/settingsChanged"},
            
            @"pencilChargingIndicator":@{
                    @"keyInOtherPref":@"appearance",
                    @"keyType":@"string",
                    @"mode":@"CF",
                    @"defaultValueWhenDark":@"1",
                    @"defaultValueWhenLight":@"0",
                    @"plistName":@"com.shiftcmdk.pencilchargingindicatorpreferences",
                    @"notificationName":@"com.shiftcmdk.pencilchargingindicatorpreferences.prefschanged"},
            
            @"ringer13":@{
                    @"keyInOtherPref":@"darkMode",
                    @"keyType":@"bool",
                    @"mode":@"NS",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"plistName":@"com.kingpuffdaddi.ringer13prefs",
                    @"notificationName":@"com.kingpuffdaddi.ringer13prefs/settingschanged"},
            
            @"tacitus":@{
                    @"keyInOtherPref":@"Style",
                    @"keyType":@"number",
                    @"mode":@"CF",
                    @"defaultValueWhenDark":@"1",
                    @"defaultValueWhenLight":@"2",
                    @"plistName":@"com.twickd.tacituspreferences",
                    @"notificationName":@"com.tacitus.config/refresh"},
            
            @"ultrasound":@{
                    @"keyInOtherPref":@"Theme",
                    @"keyType":@"string",
                    @"mode":@"CF",
                    @"defaultValueWhenDark":@"ABVolumeHUDThemeDark",
                    @"defaultValueWhenLight":@"ABVolumeHUDThemeExtraLight",
                    @"plistName":@"applebetas.ios.tweak.willow",
                    @"notificationName":@"applebetas.ios.tweak.willow.changed"},
            
            @"XIIIHUDMute":@{
                    @"keyInOtherPref":@"darkMode",
                    @"keyType":@"bool",
                    @"mode":@"CF",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"plistName":@"com.xcxiao.xiiihudpb",
                    @"notificationName":@"com.xcxiao.xiiihudpb"}
    };
}
@end
