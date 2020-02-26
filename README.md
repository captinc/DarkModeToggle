# DarkModeToggle v1.2
Enable/disable specific tweaks when toggling dark mode

Compatible with iOS 11.0+

Repo: [https://captinc.github.io](https://captinc.github.io)

[Direct .deb download](https://github.com/captinc/DarkModeToggle/releases/download/v1.2/com.captinc.darkmodetoggle_1.2_iphoneos-arm.deb)

[Reddit post](https://www.reddit.com/r/jailbreak/comments/euiss0/release_darkmodetoggle_enabledisable_specific)

[Screenshots](https://captinc.github.io/depictions/darkmodetoggle/screenshots.html)

# How to compile
1. [Install theos](https://github.com/theos/theos/wiki/Installation-macOS) on your Mac
2. Make sure you installed the iOS 11.2 patched SDK for theos
3. `git clone https://github.com/captinc/DarkModeToggle.git ./DarkModeToggle-master`
4. `cd ./DarkModeToggle-master`
5. `make package`

A .deb will now be in the "DarkModeToggle-master/packages" folder

# License
Please do not verbatim copy my tweak, call it your own, and redistribute it. You can use individual parts of my code for your own non-commercial projects. There is no warranty. If you have any questions, [PM me on Reddit](https://www.reddit.com/message/compose/?to=captinc37&subject=GitHub%20question)

# Developer documentation
How to programmatically enable/disable DarkModeToggle from another tweak:
1. Set `dark` or `light` for the `darkModeState` key in `/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist`
2. Post this NSDistributedNotification: `com.captinc.darkmodetoggle.updateState`

How to programmatically detect when DarkModeToggle is toggled:
1. Listen for this NSDistributedNotification: `com.captinc.darkmodetoggle.stateChanged`

Note: because my tweak uses NSDistributedNotifications instead of NSNotifications, you can enable/disable/detect DarkModeToggle from any process 

# Code examples
Before starting, place this at the top of your code:
```objective-c
@interface NSDistributedNotificationCenter : NSNotificationCenter
@end
```

Enable DarkModeToggle:
```objective-c
NSString *plistPath = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist";
NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
if (!prefs) {
    prefs = [[NSMutableDictionary alloc] init];
}
[prefs setObject:@"dark" forKey:@"darkModeState"];
[prefs writeToFile:plistPath atomically:YES];
[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.captinc.darkmodetoggle.updateState" object:nil userInfo:nil];
```

Disable DarkModeToggle:
```objective-c
NSString *plistPath = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist";
NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
if (!prefs) {
    prefs = [[NSMutableDictionary alloc] init];
}
[prefs setObject:@"light" forKey:@"darkModeState"];
[prefs writeToFile:plistPath atomically:YES];
[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.captinc.darkmodetoggle.updateState" object:nil userInfo:nil];
```

Toggle DarkModeToggle to the opposite state:
```objective-c
NSString *plistPath = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.plist";
NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
if (!prefs) {
    prefs = [[NSMutableDictionary alloc] init];
}
NSString *currentState = [prefs objectForKey:@"darkModeState"];

if ([currentState isEqualToString:@"dark"]) {
    [prefs setObject:@"light" forKey:@"darkModeState"];
}
else if ([currentState isEqualToString:@"light"]) {
    [prefs setObject:@"dark" forKey:@"darkModeState"];
}
[prefs writeToFile:plistPath atomically:YES];
[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.captinc.darkmodetoggle.updateState" object:nil userInfo:nil];
```

Detect when DarkModeToggle is toggled: 
```objective-c
- (void)oneOfYourMethods {
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(itWasToggled) name:@"com.captinc.darkmodetoggle.stateChanged" object:nil];
}
- (void)itWasToggled {
    doSomething();
}
```
