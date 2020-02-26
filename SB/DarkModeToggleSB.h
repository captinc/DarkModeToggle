@interface DarkModeToggleSB : NSObject
+ (instancetype)sharedInstance;

- (void)showAlert:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC;
- (void)runScript:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC askToRespring:(bool)askToRespring respringImmediately:(bool)respringImmediately message:(NSString *)msg;
- (void)respring;

- (void)makeAlertDarkIfNecessary:(UIAlertController *)alert;
- (void)addButtonsToAlert:(UIAlertController *)alert;

- (void)updatePrefsForOtherTweaks:(NSString *)changeToMode;
- (NSDictionary *)infoAboutOtherTweaks;
@end

@interface SpringBoard : UIApplication //required for Noctis support
- (void)darkModeChanged;
@end
