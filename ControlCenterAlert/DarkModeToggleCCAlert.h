@interface DarkModeToggleCCAlert : UIViewController
+ (instancetype)sharedInstance;
- (void)makeAlertDarkIfNecessary:(UIAlertController *)alert;
- (void)addButtonsToAlert:(UIAlertController *)alert;
- (void)showAlert:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC;
- (void)runScript:(NSString *)changeToMode CCViewController:(UIViewController *)CCVC askToRespring:(bool)askToRespring respringImmediately:(bool)respringImmediately message:(NSString *)msg;
- (void)respring;
@end
