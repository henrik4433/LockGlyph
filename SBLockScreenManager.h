@interface SBLockScreenViewControllerBase : UIViewController
- (_Bool)isPasscodeLockVisible;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
- (void)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
- (void)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2;
- (void)_bioAuthenticated:(id)arg1;
@property(nonatomic, getter=isUIUnlocking) _Bool UIUnlocking;
@property(readonly) _Bool isWaitingToLockUI;
@property(readonly) _Bool isUILocked;
@property(readonly, nonatomic) SBLockScreenViewControllerBase *lockScreenViewController;
@property(readonly) _Bool bioAuthenticatedWhileMenuButtonDown;
@end