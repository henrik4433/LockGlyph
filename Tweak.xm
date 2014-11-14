#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import "PKGlyphView.h"
#import "SBLockScreenManager.h"

#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDNotMatched  10

#define kDefaultPrimaryColor [[UIColor alloc] initWithRed:188/255.0f green:188/255.0f blue:188/255.0f alpha:1.0f]
#define kDefaultSecondaryColor [[UIColor alloc] initWithRed:119/255.0f green:119/255.0f blue:119/255.0f alpha:1.0f]

UIView *lockView = nil;
PKGlyphView *fingerglyph = nil;
SystemSoundID unlockSound;

BOOL authenticated;
BOOL shouldNotDelay;
BOOL usingGlyph;

BOOL enabled;
BOOL useUnlockSound;
BOOL useTickAnimation;
BOOL useFasterAnimations;
BOOL vibrateOnIncorrectFinger;
BOOL shakeOnIncorrectFinger;
UIColor *primaryColor;
UIColor *secondaryColor;

static UIColor* parseColorFromPreferences(NSString* string) {
	NSArray *prefsarray = [string componentsSeparatedByString: @":"];
	NSString *hexString = [prefsarray objectAtIndex:0];
	double alpha = [[prefsarray objectAtIndex:1] doubleValue];

	unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [[UIColor alloc] initWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

static void loadPreferences() {
    CFPreferencesAppSynchronize(CFSTR("com.evilgoldfish.lockglyph"));
    enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	useUnlockSound = !CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	useTickAnimation = !CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	useFasterAnimations = !CFPreferencesCopyAppValue(CFSTR("useFasterAnimations"), CFSTR("com.evilgoldfish.lockglyph")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("useFasterAnimations"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	vibrateOnIncorrectFinger = !CFPreferencesCopyAppValue(CFSTR("vibrateOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("vibrateOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	shakeOnIncorrectFinger = !CFPreferencesCopyAppValue(CFSTR("shakeOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("shakeOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	primaryColor = !CFPreferencesCopyAppValue(CFSTR("primaryColor"), CFSTR("com.evilgoldfish.lockglyph")) ? kDefaultPrimaryColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("primaryColor"), CFSTR("com.evilgoldfish.lockglyph")));
 	secondaryColor = !CFPreferencesCopyAppValue(CFSTR("secondaryColor"), CFSTR("com.evilgoldfish.lockglyph")) ? kDefaultSecondaryColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("secondaryColor"), CFSTR("com.evilgoldfish.lockglyph")));
}

%hook SBLockScreenScrollView

-(void)didMoveToWindow {
	if (enabled) {
		lockView = (UIView *)self;
		usingGlyph = YES;
		authenticated = NO;
		fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:1];
		fingerglyph.delegate = (id<PKGlyphViewDelegate>)self;
		fingerglyph.secondaryColor = secondaryColor;
		fingerglyph.primaryColor = primaryColor;
		fingerglyph.userInteractionEnabled = NO;
		CGRect screen = [[UIScreen mainScreen] bounds];
		fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
		[self addSubview:fingerglyph];
	}
}

%new(v@:)
-(void)performFingerScanAnimation {
	[fingerglyph setState:1 animated:YES completionHandler:nil];
}

%new
- (void)resetFingerScanAnimation {
	[fingerglyph setState:0 animated:YES completionHandler:nil];
}

%new
- (void)performShakeFingerFailAnimation {
	CABasicAnimation *shakeanimation = [CABasicAnimation animationWithKeyPath:@"position"];
	[shakeanimation setDuration:0.05];
	[shakeanimation setRepeatCount:4];
	[shakeanimation setAutoreverses:YES];
	[shakeanimation setFromValue:[NSValue valueWithCGPoint:CGPointMake(fingerglyph.center.x - 10, fingerglyph.center.y)]];
	[shakeanimation setToValue:[NSValue valueWithCGPoint:CGPointMake(fingerglyph.center.x + 10, fingerglyph.center.y)]];
	[[fingerglyph layer] addAnimation:shakeanimation forKey:@"position"];
}

%new(v@:)
-(void)performTickAnimation {
	[fingerglyph setState:6 animated:YES completionHandler:nil];
}

%new(v@:@c)
- (void)glyphView:(PKGlyphView *)arg1 revealingCheckmark:(BOOL)arg2 {
	if (useUnlockSound && useTickAnimation) {
		AudioServicesPlaySystemSound(unlockSound);
	}
}

%end

%hook PKFingerprintGlyphView

-(void)_setProgress:(double)arg1 withDuration:(double)arg2 forShapeLayerAtIndex:(unsigned long long)arg {
	if (lockView && enabled && useFasterAnimations && usingGlyph) {
		if (authenticated) {
			arg2 = MIN(arg2, 0.1);
		} else {
			arg1 = MIN(arg1, 0.8);
			arg2 *= 0.5;
		}
	}
	%orig;
}

- (double)_minimumAnimationDurationForStateTransition {
	return authenticated && useFasterAnimations && usingGlyph ? 0.1 : %orig;
}

%end

%hook SBLockScreenManager

- (void)_bioAuthenticated:(id)arg1 {
	if (lockView && self.isUILocked && enabled && !shouldNotDelay) {
		authenticated = YES;
		[lockView performSelectorOnMainThread:@selector(performTickAnimation) withObject:nil waitUntilDone:YES];
		double delayInSeconds = 1.3;
		if (!useTickAnimation) {
			delayInSeconds = 0.3;
		}
		if (useFasterAnimations) {
			delayInSeconds = 0.5;
			if (!useTickAnimation) {
				delayInSeconds = 0.1;
			}
		}
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){ 
			if (!useTickAnimation && useUnlockSound) {
				AudioServicesPlaySystemSound(unlockSound);
			}
			fingerglyph.delegate = nil;
			[lockView performSelectorOnMainThread:@selector(resetFingerScanAnimation) withObject:nil waitUntilDone:YES];
			shouldNotDelay = NO;
			usingGlyph = NO;
			lockView = nil;
			fingerglyph = nil;
			%orig; });
	} else {
		%orig;
	}
}

- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)arg2 {
	%orig;
	//start animation
	if (lockView && self.isUILocked && enabled && !authenticated) {
		switch (arg2) {
			case TouchIDFingerDown:
				[lockView performSelectorOnMainThread:@selector(performFingerScanAnimation) withObject:nil waitUntilDone:YES];
				break;
			case TouchIDFingerUp:
				[lockView performSelectorOnMainThread:@selector(resetFingerScanAnimation) withObject:nil waitUntilDone:YES];
				break;
			case TouchIDNotMatched:
			if (shakeOnIncorrectFinger) {
				[lockView performSelectorOnMainThread:@selector(performShakeFingerFailAnimation) withObject:nil waitUntilDone:YES];
			}
			if (vibrateOnIncorrectFinger) {
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			}
				break;
		}
	}
}

%end

%hook SBLockScreenView

- (void)_layoutSlideToUnlockView {
	if (enabled) {
		return;
	}
	%orig;
}

%end

%hook SBLockScreenViewController

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	%orig;
	CGRect screen = [[UIScreen mainScreen] bounds];
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		fingerglyph.center = CGPointMake(screen.size.height+CGRectGetMidY(screen),screen.size.width-60);
	} else {
		fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
	}
}

/*- (void)_removePasscodeOverlayWithCompletion:(CDUnknownBlockType)arg1 {
	shouldNotDelay = 
}

- (void)_addPasscodeOverlayWithCompletion:(CDUnknownBlockType)arg1 {

}*/

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)loadPreferences,
                                    CFSTR("com.evilgoldfish.lockglyph.settingschanged"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
	loadPreferences();
	NSURL *pathURL = [NSURL fileURLWithPath: @"/System/Library/Frameworks/PassKit.framework/Payment_Success.wav"];
	AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &unlockSound);
	[pool release];
}