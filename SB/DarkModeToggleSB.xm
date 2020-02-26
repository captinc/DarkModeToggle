//Adding support for a new toggle from another tweak usually only requires 2 things:
//1. Add an entry in PrefsForOtherTweaks.plist
//2. Add an entry in "- (NSDictionary *)infoAboutOtherTweaks"
//However, some tweaks may require special handling (such as Noctis and SnowBoard)

//Note: if you added support for another toggle/tweak and DarkModeToggle doesn't change the value in that tweak's plist, the FIRST thing you should try is this:
//    1. Go to that toggle/tweak's entry in "- (NSDictionary *)infoAboutOtherTweaks"
//    2. Change |@"mode":@"CF",| to |@"mode":@"NS",| (vice versa applies too). Do not include the "|"

#import "DarkModeToggleSB.h"
#import "../Shared.h"
#import "../NSTask.h"

@implementation DarkModeToggleSB
+ (instancetype)sharedInstance {
    static DarkModeToggleSB *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (void)showAlert:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC { //shows the UIAlertController you see in Control Center when using my tweak
    NSDictionary *rootDict = [NSDictionary dictionaryWithContentsOfFile:plistPath]; //load prefs
    NSString *respringMode = [rootDict objectForKey:@"respringMode"];
    if (!respringMode) {
        respringMode = @"ask";
    }
    BOOL shouldRunScript = [[rootDict objectForKey:@"runScripts"] boolValue];
    
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
    if ([changeToMode isEqualToString:@"enable"]) {
        prefsKeyForCurrentState = @"prefsForOthersInDarkMode";
        defaultValueForCurrentState = @"defaultValueWhenDark";
    }
    else {
        prefsKeyForCurrentState = @"prefsForOthersInLightMode";
        defaultValueForCurrentState = @"defaultValueWhenLight";
    }
    
    NSDictionary *rootDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSDictionary *prefsForOthers = [rootDict objectForKey:prefsKeyForCurrentState];
    if (!prefsForOthers) {
        prefsForOthers = [[NSDictionary alloc] init];
    }
    NSDictionary *infoAboutOtherTweaks = [self infoAboutOtherTweaks];
    
    for (NSString *tweak in infoAboutOtherTweaks) {
        BOOL isChangingPrefsEnabled = [[prefsForOthers objectForKey:[tweak stringByAppendingString:@"-enabled"]] boolValue];
        if (isChangingPrefsEnabled) { //if the enabled switch is on for the tweak referenced in this loop iteration
            //load information for the tweak handled in this loop iteration
            NSDictionary *infoAboutTweak = [infoAboutOtherTweaks objectForKey:tweak];
            NSString *keyInOtherPref = [infoAboutTweak objectForKey:@"keyInOtherPref"];
            NSString *keyType = [infoAboutTweak objectForKey:@"keyType"];
            NSString *keyForValueInCurrentState = [tweak stringByAppendingString:@"-value"]; //load the wanted value for the current dark mode state
            id valueInCurrentState = [prefsForOthers objectForKey:keyForValueInCurrentState];
            if (!valueInCurrentState) { //always check if what we got from the .plist is nil and handle accordingly
                valueInCurrentState = [infoAboutTweak objectForKey:defaultValueForCurrentState];
            }
            NSString *mode = [infoAboutTweak objectForKey:@"mode"];
            NSString *plistName = [infoAboutTweak objectForKey:@"plistName"];
            NSString *notificationName = [infoAboutTweak objectForKey:@"notificationName"]; //see below for an explanation about this
            
            //convert the wanted value to the appropriate data type for use with either the CF method or NS method (explanation below)
            CFPropertyListRef valueToSetForCFMode;
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
            else if ([keyType isEqualToString:@"array"]) {
                valueToSetForCFMode = (__bridge CFArrayRef)valueInCurrentState;
                valueToSetForNSMode = valueInCurrentState;
            }
            
            //actually set the pref value for the other tweak
            if ([mode isEqualToString:@"special"]) { //some tweaks require special handling
                NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@%@", plistName, @".plist"];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
                if (!dict) {
                    dict = [[NSMutableDictionary alloc] init];
                }
                BOOL existingValue = [[dict objectForKey:keyInOtherPref] boolValue]; //the current value in the other tweak's plist
                BOOL wantedValue = [valueInCurrentState boolValue];
                
                //only toggle the other tweak if it's not in the state we want and if it's installed
                if ([tweak isEqualToString:@"noctis12"]) {
                    SpringBoard *sb = (SpringBoard *)[%c(SpringBoard) sharedApplication];
                    BOOL noctis12IsInstalled = [sb respondsToSelector:@selector(darkModeChanged)];
                    if (existingValue != wantedValue && noctis12IsInstalled) {
                        [sb darkModeChanged]; //this method is provided by Noctis. it toggles Noctis to the opposite state
                    }
                }
                continue;
            }
            else if ([mode isEqualToString:@"NS"]) { //for some reason, CFPreferencesSetAppValue() does not work for some tweaks, so use NSMutableDictionary instead
                NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@%@", plistName, @".plist"];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
                if (!dict) {
                    dict = [[NSMutableDictionary alloc] init];
                }
                [dict setObject:valueToSetForNSMode forKey:keyInOtherPref];
                [dict writeToFile:path atomically:YES];
            }
            else if ([mode isEqualToString:@"CF"]) { //normal mode
                CFPreferencesSetAppValue((__bridge CFStringRef)keyInOtherPref, valueToSetForCFMode, (__bridge CFStringRef)plistName);
            }
            
            //if necessary, post a notification telling that tweak to update its prefs
            //must use CFNotificationCenter instead of NSNotificationCenter because this notification needs to be global (cross between processes)
            if (![notificationName isEqual:[NSNull null]]) {
                CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)notificationName, nil, nil, true);
            }
        }
    }
}

- (NSDictionary *)infoAboutOtherTweaks { //a list of necessary information for changing prefs of another tweak
    return @{
            @"betterAlerts":@{
                    @"keyInOtherPref":@"blurOption",
                    @"keyType":@"string",
                    @"defaultValueWhenDark":@"3",
                    @"defaultValueWhenLight":@"2",
                    @"mode":@"CF",
                    @"plistName":@"com.adamseiter.betteralerts",
                    @"notificationName":@"com.adamseiter.betteralerts/preferencesChanged"},
            
            @"callBarXS":@{
                    @"keyInOtherPref":@"viewStyle",
                    @"keyType":@"number",
                    @"defaultValueWhenDark":@"5",
                    @"defaultValueWhenLight":@"4",
                    @"mode":@"CF",
                    @"plistName":@"net.limneos.callbarx",
                    @"notificationName":@"net.limneos.callbarx.settingsChanged"},
            
            @"complications":@{
                    @"keyInOtherPref":@"backgroundStyle",
                    @"keyType":@"string",
                    @"defaultValueWhenDark":@"Dark",
                    @"defaultValueWhenLight":@"Light",
                    @"mode":@"CF",
                    @"plistName":@"com.bengiannis.complicationsprefs",
                    @"notificationName":[NSNull null]},
            
            @"grupi":@{
                    @"keyInOtherPref":@"CellStyle",
                    @"keyType":@"number",
                    @"defaultValueWhenDark":@"1",
                    @"defaultValueWhenLight":@"0",
                    @"mode":@"CF",
                    @"plistName":@"com.peterdev.grupi",
                    @"notificationName":@"com.peterdev.grupi/ReloadPrefs"},
            
            @"mot":@{
                    @"keyInOtherPref":@"isDarkModeEnabled",
                    @"keyType":@"bool",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"mode":@"CF",
                    @"plistName":@"com.donbytyqi.mot",
                    @"notificationName":@"com.donbytyqi.mot/settingsChanged"},
            
            @"noctis12":@{
                    @"keyInOtherPref":@"enabled",
                    @"keyType":@"bool",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"mode":@"special",
                    @"plistName":@"com.laughingquoll.noctis12prefs.settings",
                    @"notificationName":[NSNull null]},
            
            @"pencilChargingIndicator":@{
                    @"keyInOtherPref":@"appearance",
                    @"keyType":@"string",
                    @"defaultValueWhenDark":@"1",
                    @"defaultValueWhenLight":@"0",
                    @"mode":@"CF",
                    @"plistName":@"com.shiftcmdk.pencilchargingindicatorpreferences",
                    @"notificationName":@"com.shiftcmdk.pencilchargingindicatorpreferences.prefschanged"},
            
            @"pullOverPro":@{
                    @"keyInOtherPref":@"darkHandle",
                    @"keyType":@"bool",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"mode":@"CF",
                    @"plistName":@"com.c1d3r.PullOverPro",
                    @"notificationName":[NSNull null]},
            
            @"ringer13":@{
                    @"keyInOtherPref":@"darkMode",
                    @"keyType":@"bool",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"mode":@"NS",
                    @"plistName":@"com.kingpuffdaddi.ringer13prefs",
                    @"notificationName":@"com.kingpuffdaddi.ringer13prefs/settingschanged"},
            
            @"selectionPlus":@{
                    @"keyInOtherPref":@"BlurStyle",
                    @"keyType":@"number",
                    @"defaultValueWhenDark":@"2",
                    @"defaultValueWhenLight":@"1",
                    @"mode":@"NS",
                    @"plistName":@"com.satvikb.selectionplusprefs",
                    @"notificationName":@"com.satvikb.selectionplusprefs/ReloadPrefs"},
            
            @"sileo":@{
                    @"keyInOtherPref":@"darkMode",
                    @"keyType":@"bool",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"mode":@"CF",
                    @"plistName":@"org.coolstar.SileoStore",
                    @"notificationName":[NSNull null]},
            
            @"snowBoard":@{
                    @"keyInOtherPref":@"ActiveMenuItems",
                    @"keyType":@"array",
                    @"defaultValueWhenDark":[[NSArray alloc] init],
                    @"defaultValueWhenLight":[[NSArray alloc] init],
                    @"mode":@"NS",
                    @"plistName":@"com.spark.snowboardprefs",
                    @"notificationName":@"com.spark.snowboard.refreshNow"},
            
            @"tacitus":@{
                    @"keyInOtherPref":@"Style",
                    @"keyType":@"number",
                    @"defaultValueWhenDark":@"1",
                    @"defaultValueWhenLight":@"2",
                    @"mode":@"CF",
                    @"plistName":@"com.twickd.tacituspreferences",
                    @"notificationName":@"com.tacitus.config/refresh"},
            
            @"ultrasound":@{
                    @"keyInOtherPref":@"Theme",
                    @"keyType":@"string",
                    @"defaultValueWhenDark":@"ABVolumeHUDThemeDark",
                    @"defaultValueWhenLight":@"ABVolumeHUDThemeExtraLight",
                    @"mode":@"CF",
                    @"plistName":@"applebetas.ios.tweak.willow",
                    @"notificationName":@"applebetas.ios.tweak.willow.changed"},
            
            @"XIIIHUDMute":@{
                    @"keyInOtherPref":@"darkMode",
                    @"keyType":@"bool",
                    @"defaultValueWhenDark":@"YES",
                    @"defaultValueWhenLight":@"NO",
                    @"mode":@"CF",
                    @"plistName":@"com.xcxiao.xiiihudpb",
                    @"notificationName":@"com.xcxiao.xiiihudpb"}
    };
}
@end
