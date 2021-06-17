

#import "Appirater.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>


#define HOME NSHomeDirectory()
#define DOCUMENTS [HOME stringByAppendingPathComponent:@"Documents"]
#define PATH_LINGUAGEM [DOCUMENTS stringByAppendingPathComponent:@"Linguagem.plist"]


#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

NSString *const kAppiraterFirstUseDate				= @"kAppiraterFirstUseDate";
NSString *const kAppiraterUseCount					= @"kAppiraterUseCount";
NSString *const kAppiraterSignificantEventCount		= @"kAppiraterSignificantEventCount";
NSString *const kAppiraterCurrentVersion			= @"kAppiraterCurrentVersion";
NSString *const kAppiraterRatedCurrentVersion		= @"kAppiraterRatedCurrentVersion";
NSString *const kAppiraterDeclinedToRate			= @"kAppiraterDeclinedToRate";
NSString *const kAppiraterReminderRequestDate		= @"kAppiraterReminderRequestDate";

NSString *templateReviewURL = @"https://itunes.apple.com/us/app/tcolors/id884908481?l=pt&ls=1&mt=8";
NSString *templateReviewURLiOS7 = @"https://itunes.apple.com/us/app/tcolors/id884908481?l=pt&ls=1&mt=8";

static NSString *_appId;
static double _daysUntilPrompt = 2;
static NSInteger _usesUntilPrompt = 2;
static NSInteger _significantEventsUntilPrompt = -1;
static double _timeBeforeReminding = 1;
static BOOL _debug = YES;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0
	static id<AppiraterDelegate> _delegate;
#else
	__weak static id<AppiraterDelegate> _delegate;
#endif
static BOOL _usesAnimation = TRUE;
static UIStatusBarStyle _statusBarStyle;
static BOOL _modalOpen = false;
static BOOL _alwaysUseMainBundle = NO;

@interface Appirater ()
@property (nonatomic, copy) NSString *alertTitle;
@property (nonatomic, copy) NSString *alertMessage;
@property (nonatomic, copy) NSString *alertCancelTitle;
@property (nonatomic, copy) NSString *alertRateTitle;
@property (nonatomic, copy) NSString *alertRateLaterTitle;
- (BOOL)connectedToNetwork;
+ (Appirater*)sharedInstance;
- (void)showPromptWithChecks:(BOOL)withChecks
      displayRateLaterButton:(BOOL)displayRateLaterButton;
- (void)showRatingAlert:(BOOL)displayRateLaterButton;
- (void)showRatingAlert;
- (BOOL)ratingConditionsHaveBeenMet;
- (void)incrementUseCount;
- (void)hideRatingAlert;
@end

@implementation Appirater 

@synthesize ratingAlert;

+ (void) setAppId:(NSString *)appId {
    _appId = @"884908481";
}

+ (void) setDaysUntilPrompt:(double)value {
    _daysUntilPrompt = value;
}

+ (void) setUsesUntilPrompt:(NSInteger)value {
    _usesUntilPrompt = value;
}

+ (void) setSignificantEventsUntilPrompt:(NSInteger)value {
    _significantEventsUntilPrompt = value;
}

+ (void) setTimeBeforeReminding:(double)value {
    _timeBeforeReminding = value;
}

+ (void) setCustomAlertTitle:(NSString *)title
{
    [self sharedInstance].alertTitle = title;
}

+ (void) setCustomAlertMessage:(NSString *)message
{
    [self sharedInstance].alertMessage = message;
}

+ (void) setCustomAlertCancelButtonTitle:(NSString *)cancelTitle
{
    [self sharedInstance].alertCancelTitle = cancelTitle;
}

+ (void) setCustomAlertRateButtonTitle:(NSString *)rateTitle
{
    [self sharedInstance].alertRateTitle = rateTitle;
}

+ (void) setCustomAlertRateLaterButtonTitle:(NSString *)rateLaterTitle
{
    [self sharedInstance].alertRateLaterTitle = rateLaterTitle;
}

+ (void) setDebug:(BOOL)debug {
    _debug = debug;
}
+ (void)setDelegate:(id<AppiraterDelegate>)delegate{
	_delegate = delegate;
}
+ (void)setUsesAnimation:(BOOL)animation {
	_usesAnimation = animation;
}
+ (void)setOpenInAppStore:(BOOL)openInAppStore {
    [Appirater sharedInstance].openInAppStore = openInAppStore;
}
+ (void)setStatusBarStyle:(UIStatusBarStyle)style {
	_statusBarStyle = style;
}
+ (void)setModalOpen:(BOOL)open {
	_modalOpen = open;
}
+ (void)setAlwaysUseMainBundle:(BOOL)alwaysUseMainBundle {
    _alwaysUseMainBundle = alwaysUseMainBundle;
}

+ (NSBundle *)bundle
{
    NSBundle *bundle;

    if (_alwaysUseMainBundle) {
        bundle = [NSBundle mainBundle];
    } else {
        NSURL *appiraterBundleURL = [[NSBundle mainBundle] URLForResource:@"Appirater" withExtension:@"bundle"];

        if (appiraterBundleURL) {
            // Appirater.bundle will likely only exist when used via CocoaPods
            bundle = [NSBundle bundleWithURL:appiraterBundleURL];
        } else {
            bundle = [NSBundle mainBundle];
        }
    }

    return bundle;
}

- (NSString *)alertTitle
{
    

    return _alertTitle ? _alertTitle : APPIRATER_MESSAGE_TITLE;
    

}


- (NSString *)alertTitleESPANHOL
{
    

        return _alertTitle ? _alertTitle : APPIRATER_MESSAGE_TITLEESPANHOL;

    
}


- (NSString *)alertTitlePORTUGUES
{
    
    
    return _alertTitle ? _alertTitle : APPIRATER_MESSAGE_TITLEPORTUGUES;
    
    
}



- (NSString *)alertMessage
{
    

    
    return _alertMessage ? _alertMessage : APPIRATER_MESSAGE;
    

    
    
}


- (NSString *)alertMessageESPANHOL
{
    

        
        return _alertTitle ? _alertTitle : APPIRATER_MESSAGEESPANHOL;
    
    
}


- (NSString *)alertMessagePORTUGUES
{
    
    
    return _alertTitle ? _alertTitle : APPIRATER_MESSAGEPORTUGUES;
    
    
}



- (NSString *)alertCancelTitle
{

    
    return _alertCancelTitle ? _alertCancelTitle : APPIRATER_CANCEL_BUTTON;
    

    
}


- (NSString *)alertCancelTitleESPANHOL
{
    

        
        return _alertTitle ? _alertTitle : APPIRATER_CANCEL_BUTTONESPANHOL;
        

    
}

- (NSString *)alertCancelTitlePORTUGUES
{
    
    
    
    return _alertTitle ? _alertTitle : APPIRATER_CANCEL_BUTTONPORTUGUES;
    
    
    
}


- (NSString *)alertRateTitle
{
    

    
    return _alertRateTitle ? _alertRateTitle : APPIRATER_RATE_BUTTON;
    

    
    
}



- (NSString *)alertRateTitleESPANHOL
{
    

        
        return _alertTitle ? _alertTitle : APPIRATER_RATE_BUTTONPORTUGUES;
    
    
}



- (NSString *)alertRateTitlePORTUGUES
{
    
    
    
    return _alertTitle ? _alertTitle : APPIRATER_RATE_BUTTONPORTUGUES;
    
    
}



- (NSString *)alertRateLaterTitle
{
    
    

    
    return _alertRateLaterTitle ? _alertRateLaterTitle : APPIRATER_RATE_LATER;
    

    
}



- (NSString *)alertRateLaterTitleESPANHOL
{
    

        
        return _alertTitle ? _alertTitle : APPIRATER_RATE_LATERESPANHOL;
    
    
}


- (NSString *)alertRateLaterTitlePORTUGUES
{
    
    
    
    return _alertTitle ? _alertTitle : APPIRATER_RATE_LATERPORTUGUES;
    
    
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    self = [super init];
    if (self) {
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
            self.openInAppStore = YES;
        } else {
            self.openInAppStore = NO;
        }
    }
    
    return self;
}

- (BOOL)connectedToNetwork {
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    Boolean didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
	
	NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
	
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}

+ (Appirater*)sharedInstance {
	static Appirater *appirater = nil;
	if (appirater == nil)
	{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            appirater = [[Appirater alloc] init];
			appirater.delegate = _delegate;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:
                UIApplicationWillResignActiveNotification object:nil];
        });
	}
	
	return appirater;
}

- (void)showRatingAlert:(BOOL)displayRateLaterButton {
  UIAlertView *alertView = nil;
  if (displayRateLaterButton) {
      
    
      NSDictionary *dicionario = [NSDictionary dictionaryWithContentsOfFile:PATH_LINGUAGEM];
      
      NSNumber *idioma = [dicionario objectForKey:@"Linguagem"];
      
      int idioma2 = [idioma intValue];
      
      
      if (idioma2 == 0) {
          alertView = [[UIAlertView alloc] initWithTitle:self.alertTitle
                                                 message:self.alertMessage
                                                delegate:self
                                       cancelButtonTitle:self.alertCancelTitle
                                       otherButtonTitles:self.alertRateTitle, self.alertRateLaterTitle, nil];
      }
      else if (idioma2 == 1){
          alertView = [[UIAlertView alloc] initWithTitle:self.alertTitleESPANHOL
                                                 message:self.alertMessageESPANHOL
                                                delegate:self
                                       cancelButtonTitle:self.alertCancelTitleESPANHOL
                                       otherButtonTitles:self.alertRateTitleESPANHOL, self.alertRateLaterTitleESPANHOL, nil];
          
      }
      else if (idioma2 == 2){
          alertView = [[UIAlertView alloc] initWithTitle:self.alertTitlePORTUGUES
                                                 message:self.alertMessagePORTUGUES
                                                delegate:self
                                       cancelButtonTitle:self.alertCancelTitlePORTUGUES
                                       otherButtonTitles:self.alertRateTitlePORTUGUES, self.alertRateLaterTitlePORTUGUES, nil];
          
      }
      
      

  } else {
      NSDictionary *dicionario = [NSDictionary dictionaryWithContentsOfFile:PATH_LINGUAGEM];
      
      NSNumber *idioma = [dicionario objectForKey:@"Linguagem"];
      
      int idioma2 = [idioma intValue];
      
      
      if (idioma2 == 0) {
          alertView = [[UIAlertView alloc] initWithTitle:self.alertTitle
                                                 message:self.alertMessage
                                                delegate:self
                                       cancelButtonTitle:self.alertCancelTitle
                                       otherButtonTitles:self.alertRateTitle, self.alertRateLaterTitle, nil];
      }
      else if (idioma2 == 1){
          alertView = [[UIAlertView alloc] initWithTitle:self.alertTitleESPANHOL
                                                 message:self.alertMessageESPANHOL
                                                delegate:self
                                       cancelButtonTitle:self.alertCancelTitleESPANHOL
                                       otherButtonTitles:self.alertRateTitleESPANHOL, self.alertRateLaterTitleESPANHOL, nil];
          
      }
      else if (idioma2 == 2){
          alertView = [[UIAlertView alloc] initWithTitle:self.alertTitlePORTUGUES
                                                 message:self.alertMessagePORTUGUES
                                                delegate:self
                                       cancelButtonTitle:self.alertCancelTitlePORTUGUES
                                       otherButtonTitles:self.alertRateTitlePORTUGUES, self.alertRateLaterTitlePORTUGUES, nil];
          
      }
      
      
  }

	self.ratingAlert = alertView;
    [alertView show];

    id <AppiraterDelegate> delegate = _delegate;
    if (delegate && [delegate respondsToSelector:@selector(appiraterDidDisplayAlert:)]) {
             [delegate appiraterDidDisplayAlert:self];
    }
}

- (void)showRatingAlert
{
  [self showRatingAlert:true];
}

- (BOOL)ratingConditionsHaveBeenMet {
	if (_debug)
		return YES;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *dateOfFirstLaunch = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kAppiraterFirstUseDate]];
	NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:dateOfFirstLaunch];
	NSTimeInterval timeUntilRate = 60 * 60 * 24 * _daysUntilPrompt;
	if (timeSinceFirstLaunch < timeUntilRate)
		return NO;
	
	// check if the app has been used enough
	NSInteger useCount = [userDefaults integerForKey:kAppiraterUseCount];
	if (useCount < _usesUntilPrompt)
		return NO;
	
	// check if the user has done enough significant events
	NSInteger sigEventCount = [userDefaults integerForKey:kAppiraterSignificantEventCount];
	if (sigEventCount < _significantEventsUntilPrompt)
		return NO;
	
	// has the user previously declined to rate this version of the app?
	if ([userDefaults boolForKey:kAppiraterDeclinedToRate])
		return NO;
	
	// has the user already rated the app?
	if ([self userHasRatedCurrentVersion])
		return NO;
	
	// if the user wanted to be reminded later, has enough time passed?
	NSDate *reminderRequestDate = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kAppiraterReminderRequestDate]];
	NSTimeInterval timeSinceReminderRequest = [[NSDate date] timeIntervalSinceDate:reminderRequestDate];
	NSTimeInterval timeUntilReminder = 60 * 60 * 24 * _timeBeforeReminding;
	if (timeSinceReminderRequest < timeUntilReminder)
		return NO;
	
	return YES;
}

- (void)incrementUseCount {
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kAppiraterCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kAppiraterCurrentVersion];
	}
	
	if (_debug)
		NSLog(@"APPIRATER Tracking version: %@", trackingVersion);
	
	if ([trackingVersion isEqualToString:version])
	{
		// check if the first use date has been set. if not, set it.
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kAppiraterFirstUseDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kAppiraterFirstUseDate];
		}
		
		// increment the use count
		NSInteger useCount = [userDefaults integerForKey:kAppiraterUseCount];
		useCount++;
		[userDefaults setInteger:useCount forKey:kAppiraterUseCount];
		if (_debug)
			NSLog(@"APPIRATER Use count: %@", @(useCount));
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kAppiraterCurrentVersion];
		[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAppiraterFirstUseDate];
		[userDefaults setInteger:1 forKey:kAppiraterUseCount];
		[userDefaults setInteger:0 forKey:kAppiraterSignificantEventCount];
		[userDefaults setBool:NO forKey:kAppiraterRatedCurrentVersion];
		[userDefaults setBool:NO forKey:kAppiraterDeclinedToRate];
		[userDefaults setDouble:0 forKey:kAppiraterReminderRequestDate];
	}
	
	[userDefaults synchronize];
}

- (void)incrementSignificantEventCount {
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kAppiraterCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kAppiraterCurrentVersion];
	}
	
	if (_debug)
		NSLog(@"APPIRATER Tracking version: %@", trackingVersion);
	
	if ([trackingVersion isEqualToString:version])
	{
		// check if the first use date has been set. if not, set it.
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kAppiraterFirstUseDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kAppiraterFirstUseDate];
		}
		
		// increment the significant event count
		NSInteger sigEventCount = [userDefaults integerForKey:kAppiraterSignificantEventCount];
		sigEventCount++;
		[userDefaults setInteger:sigEventCount forKey:kAppiraterSignificantEventCount];
		if (_debug)
			NSLog(@"APPIRATER Significant event count: %@", @(sigEventCount));
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kAppiraterCurrentVersion];
		[userDefaults setDouble:0 forKey:kAppiraterFirstUseDate];
		[userDefaults setInteger:0 forKey:kAppiraterUseCount];
		[userDefaults setInteger:1 forKey:kAppiraterSignificantEventCount];
		[userDefaults setBool:NO forKey:kAppiraterRatedCurrentVersion];
		[userDefaults setBool:NO forKey:kAppiraterDeclinedToRate];
		[userDefaults setDouble:0 forKey:kAppiraterReminderRequestDate];
	}
	
	[userDefaults synchronize];
}

- (void)incrementAndRate:(BOOL)canPromptForRating {
	[self incrementUseCount];
	
	if (canPromptForRating &&
		[self ratingConditionsHaveBeenMet] &&
		[self connectedToNetwork])
	{
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self showRatingAlert];
                       });
	}
}

- (void)incrementSignificantEventAndRate:(BOOL)canPromptForRating {
	[self incrementSignificantEventCount];
	
	if (canPromptForRating &&
		[self ratingConditionsHaveBeenMet] &&
		[self connectedToNetwork])
	{
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self showRatingAlert];
                       });
	}
}

- (BOOL)userHasDeclinedToRate {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAppiraterDeclinedToRate];
}

- (BOOL)userHasRatedCurrentVersion {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAppiraterRatedCurrentVersion];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-implementations"
+ (void)appLaunched {
	[Appirater appLaunched:YES];
}
#pragma GCC diagnostic pop

+ (void)appLaunched:(BOOL)canPromptForRating {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[Appirater sharedInstance] incrementAndRate:canPromptForRating];
                   });
}

- (void)hideRatingAlert {
	if (self.ratingAlert.visible) {
		if (_debug)
			NSLog(@"APPIRATER Hiding Alert");
		[self.ratingAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}	
}

+ (void)appWillResignActive {
	if (_debug)
		NSLog(@"APPIRATER appWillResignActive");
	[[Appirater sharedInstance] hideRatingAlert];
}

+ (void)appEnteredForeground:(BOOL)canPromptForRating {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[Appirater sharedInstance] incrementAndRate:canPromptForRating];
                   });
}

+ (void)userDidSignificantEvent:(BOOL)canPromptForRating {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[Appirater sharedInstance] incrementSignificantEventAndRate:canPromptForRating];
                   });
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-implementations"
+ (void)showPrompt {
  [Appirater tryToShowPrompt];
}
#pragma GCC diagnostic pop

+ (void)tryToShowPrompt {
  [[Appirater sharedInstance] showPromptWithChecks:true
                            displayRateLaterButton:true];
}

+ (void)forceShowPrompt:(BOOL)displayRateLaterButton {
  [[Appirater sharedInstance] showPromptWithChecks:false
                            displayRateLaterButton:displayRateLaterButton];
}

- (void)showPromptWithChecks:(BOOL)withChecks
      displayRateLaterButton:(BOOL)displayRateLaterButton {
  bool showPrompt = true;
  if (withChecks) {
    showPrompt = ([self connectedToNetwork]
              && ![self userHasDeclinedToRate]
              && ![self userHasRatedCurrentVersion]);
  } 
  if (showPrompt) {
    [self showRatingAlert:displayRateLaterButton];
  }
}

+ (id)getRootViewController {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews])
    {
        UIResponder *responder = [subView nextResponder];
        if([responder isKindOfClass:[UIViewController class]]) {
            return [self topMostViewController: (UIViewController *) responder];
        }
    }
    
    return nil;
}

+ (UIViewController *) topMostViewController: (UIViewController *) controller {
	BOOL isPresenting = NO;
	do {
		// this path is called only on iOS 6+, so -presentedViewController is fine here.
		UIViewController *presented = [controller presentedViewController];
		isPresenting = presented != nil;
		if(presented != nil) {
			controller = presented;
		}
		
	} while (isPresenting);
	
	return controller;
}

+ (void)rateApp {
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:YES forKey:kAppiraterRatedCurrentVersion];
	[userDefaults synchronize];

	//Use the in-app StoreKit view if available (iOS 6) and imported. This works in the simulator.
	if (![Appirater sharedInstance].openInAppStore && NSStringFromClass([SKStoreProductViewController class]) != nil) {
		
		SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
		NSNumber *appId = [NSNumber numberWithInteger:_appId.integerValue];
		[storeViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:appId} completionBlock:nil];
		storeViewController.delegate = self.sharedInstance;
        
        id <AppiraterDelegate> delegate = self.sharedInstance.delegate;
		if ([delegate respondsToSelector:@selector(appiraterWillPresentModalView:animated:)]) {
			[delegate appiraterWillPresentModalView:self.sharedInstance animated:_usesAnimation];
		}
		[[self getRootViewController] presentViewController:storeViewController animated:_usesAnimation completion:^{
			[self setModalOpen:YES];
			//Temporarily use a black status bar to match the StoreKit view.
			[self setStatusBarStyle:[UIApplication sharedApplication].statusBarStyle];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
			[[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent animated:_usesAnimation];
#endif
		}];
	
	//Use the standard openUrl method if StoreKit is unavailable.
	} else {
		
		#if TARGET_IPHONE_SIMULATOR
		NSLog(@"APPIRATER NOTE: iTunes App Store is not supported on the iOS simulator. Unable to open App Store page.");
		#else
		NSString *reviewURL = [templateReviewURL stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", _appId]];

		// iOS 7 needs a different templateReviewURL @see https://github.com/arashpayan/appirater/issues/131
		if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 && [[[UIDevice currentDevice] systemVersion] floatValue] < 7.1) {
			reviewURL = [templateReviewURLiOS7 stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", _appId]];
		}

		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
		#endif
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    id <AppiraterDelegate> delegate = _delegate;
	
	switch (buttonIndex) {
		case 0:
		{
			// they don't want to rate it
			[userDefaults setBool:YES forKey:kAppiraterDeclinedToRate];
			[userDefaults synchronize];
			if(delegate && [delegate respondsToSelector:@selector(appiraterDidDeclineToRate:)]){
				[delegate appiraterDidDeclineToRate:self];
			}
			break;
		}
		case 1:
		{
			// they want to rate it
			[Appirater rateApp];
			if(delegate&& [delegate respondsToSelector:@selector(appiraterDidOptToRate:)]){
				[delegate appiraterDidOptToRate:self];
			}
			break;
		}
		case 2:
			// remind them later
			[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAppiraterReminderRequestDate];
			[userDefaults synchronize];
			if(delegate && [delegate respondsToSelector:@selector(appiraterDidOptToRemindLater:)]){
				[delegate appiraterDidOptToRemindLater:self];
			}
			break;
		default:
			break;
	}
}

//Delegate call from the StoreKit view.
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
	[Appirater closeModal];
}

//Close the in-app rating (StoreKit) view and restore the previous status bar style.
+ (void)closeModal {
	if (_modalOpen) {
		[[UIApplication sharedApplication]setStatusBarStyle:_statusBarStyle animated:_usesAnimation];
		BOOL usedAnimation = _usesAnimation;
		[self setModalOpen:NO];
		
		// get the top most controller (= the StoreKit Controller) and dismiss it
		UIViewController *presentingController = [UIApplication sharedApplication].keyWindow.rootViewController;
		presentingController = [self topMostViewController: presentingController];
		[presentingController dismissViewControllerAnimated:_usesAnimation completion:^{
            id <AppiraterDelegate> delegate = self.sharedInstance.delegate;
			if ([delegate respondsToSelector:@selector(appiraterDidDismissModalView:animated:)]) {
				[delegate appiraterDidDismissModalView:(Appirater *)self animated:usedAnimation];
			}
		}];
		[self.class setStatusBarStyle:(UIStatusBarStyle)nil];
	}
}

@end
