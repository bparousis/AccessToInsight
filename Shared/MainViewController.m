//
//  AtoIViewController.m
//  AtoI
//
//  Created by Robert Stone on 12/29/09.
//  Copyright Appmagination and Robert Stone 2009. All rights reserved.
//

#import "MainViewController.h"
#import "SettingsViewController.h"
#import "AboutViewController.h"
#import "BookmarksManager.h"
#import "ThemeManager.h"

@interface MainViewController()

@property(nonatomic, retain) UIAlertController *actionSheet;
@property(nonatomic, assign) BOOL toolbarHidden;
@property(nonatomic, retain) LocalBookmark *bookmark;
@property(nonatomic, assign) CGFloat startAlpha;

@property(nonatomic, retain) NSLayoutConstraint *topConstraint;
@property(nonatomic, retain) NSLayoutConstraint *bottomConstraint;

@end

@implementation MainViewController

@synthesize webView;
@synthesize toolbar;
@synthesize bmPopover;
@synthesize bmBarButtonItem;
@synthesize externalURL;
@synthesize actionBarButtonItem;

-(id)init {
    self = [super init];
    if (self) {
        [self addNightModeNotification];
    }
    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self addNightModeNotification];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addNightModeNotification];
    }
    return self;
}

- (void)addNightModeNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nightModeNotification:)
                                                 name:@"NightMode"
                                               object:nil];
}

- (void)nightModeNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"NightMode"]) {
        [self determineStartAlpha];
        [self updateColorScheme];
        [self.webView reload];
    }
}

#pragma mark -
#pragma mark Standard methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.toolbarHidden = NO;
    self.webView = [[[WKWebView alloc] init] autorelease];
    self.webView.navigationDelegate = self;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self determineStartAlpha];
    self.webView.opaque = NO;
    [self updateColorScheme];
    [self.view addSubview:self.webView];
    
    self.topConstraint = [NSLayoutConstraint constraintWithItem:self.webView
                                                      attribute:NSLayoutAttributeTop
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self.view
                                                      attribute:NSLayoutAttributeTop
                                                     multiplier:1.0
                                                       constant:20.0];
    [self.view addConstraint:self.topConstraint];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.webView
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.view
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                          constant:-40.0];
    [self.view addConstraint:self.bottomConstraint];
    
    
    // Load the last page the user was viewing.
    // Unfortunately I don't know of a way to save and load the history.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"lastLocationBookmark"];
    
    LocalBookmark *lastLocationBookmark = nil;
    
    if (data) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]
                                         initForReadingWithData:data];
        lastLocationBookmark = [unarchiver decodeObjectForKey:@"bookmark"];
        [unarchiver finishDecoding];
        [unarchiver release];
    }
    
    if (lastLocationBookmark != nil) {
        [self loadLocalBookmark:lastLocationBookmark];
    } else {
        [self home];
    }
}

#pragma mark -
#pragma mark Event Intercept Window delegate stuff

- (void)toggleScreenDecorations {
	// toolbar
	[UIView beginAnimations:@"toolbar" context:nil];
	if (self.toolbarHidden) {
        self.topConstraint.constant = 20.0f;
        self.bottomConstraint.constant = -40.0f;
        [self.view layoutIfNeeded];
		toolbar.frame = CGRectOffset(toolbar.frame, 0, -toolbar.frame.size.height);
		toolbar.alpha = 1;
		self.toolbarHidden = NO;
	} else {
        self.topConstraint.constant = 0.0f;
        self.bottomConstraint.constant = 0.0f;
        [self.view layoutIfNeeded];
		toolbar.frame = CGRectOffset(toolbar.frame, 0, +toolbar.frame.size.height);
		toolbar.alpha = 0;
		self.toolbarHidden = YES;
	}
	[UIView commitAnimations];
	
	// status bar
	UIApplication *application = [UIApplication sharedApplication];
	[application  setStatusBarHidden:(application.statusBarHidden ? NO : YES)];
}


- (BOOL)interceptEvent:(UIEvent *)event {
	NSSet *touches = [event allTouches];
	UITouch	*oneTouch = [touches anyObject];
	UIView *touchView = [oneTouch view];
	//	NSLog(@"tap count = %d", [oneTouch tapCount]);
	// check for taps on the web view which really end up being dispatched to
	// a scroll view
	if (touchView && [touchView isDescendantOfView:webView]
			&& touches && oneTouch.phase == UITouchPhaseBegan) {
		if ([oneTouch tapCount] == 2) {
			[self toggleScreenDecorations];
			return YES;
		}
	}	
	return NO;
}


#pragma mark -
#pragma mark Web view stuff


- (NSString *)URLStringToLocalContentPath:(NSString *)urlString {
	NSArray *urlArray = [urlString componentsSeparatedByString:LOCAL_WEB_DATA_DIR];
    return ([urlArray count] >= 2) ? [urlArray objectAtIndex:1] : nil;
}


- (void)loadLocalWebContent:(NSString *)path {
    NSString *hash = nil;
    NSRange hashRange = [path rangeOfString:@"#" options:NSBackwardsSearch];
    if (hashRange.location != NSNotFound) {
        hash = [path substringFromIndex:hashRange.location];
        path = [path substringToIndex:hashRange.location];
    }
    
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *fullPath = [NSString pathWithComponents:
						  [NSArray arrayWithObjects:resourcePath,
						   LOCAL_WEB_DATA_DIR, path, nil]];
    NSURL *url = [NSURL fileURLWithPath:fullPath];
    if (hash) {
        url = [NSURL URLWithString:hash relativeToURL:url];
    }
    
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[self.webView loadRequest:req];
}

- (void)loadLocalBookmark:(LocalBookmark *)bookmark {
	rescrollX = bookmark.scrollX;
	rescrollY = bookmark.scrollY;
	needRescroll = YES;
	[self loadLocalWebContent:bookmark.location];
}

#pragma mark -
#pragma mark Web navigation delegate

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSString *javascript = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
    
    [self.webView evaluateJavaScript:javascript completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [self.webView setAlpha:self.startAlpha];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    [self.webView setAlpha:self.startAlpha];
    [UIView animateWithDuration:1.0f animations:^{
        [self.webView setAlpha:1.0f];
    } completion:^(BOOL finished) {
    }];
    
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    NSURL *url = [navigationAction.request URL];
    
    if ([[url scheme] isEqual:@"file"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:url] == NO) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // Anything else needs to be launched externally.
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"External Link"
                                                    message:@"This link must be launched in an external application."
                          @" The current application will quit. Is this OK?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    
    // Save the external URL pending the result of the alert feedback.
    self.externalURL = url;
    
    [alert show];
    [alert release];
    
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self.webView evaluateJavaScript:[ThemeManager getCSSJavascript] completionHandler:^(id result, NSError *error) {}];
    [UIView animateWithDuration:1.0f animations:^{
        [self.webView setAlpha:1.0f];
    } completion:^(BOOL finished) {
    }];
    
    [self adjustFontForWebView];
    if (needRescroll) {
        if (rescrollY || rescrollX)
            [self scrollToX:rescrollX Y:rescrollY];
        needRescroll = NO;
    }
}

- (void)scrollToX:(NSInteger)scrollX Y:(NSInteger)scrollY {
    [self.webView evaluateJavaScript:[NSString stringWithFormat: @"window.scrollTo(%ld, %ld);",
                                      (long)scrollX, (long)scrollY] completionHandler:^(id result, NSError *error) {
    }];
}


- (void)scrollNumPages:(NSInteger)pages {
	[self.webView
      evaluateJavaScript: @"scrollY" completionHandler:^(id result, NSError *error) {
          NSInteger scrollY = [result integerValue];
          NSInteger height = self.webView.frame.size.height;
          [self scrollToX:0 Y:(scrollY + (height * pages))];
      }];
}

+ (NSInteger)textFontSize {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *textFontSizeNum = [userDefaults objectForKey:TEXT_FONT_SIZE_KEY];
    NSUInteger textFontSize = 100;
    if (textFontSizeNum) {
        textFontSize = [textFontSizeNum integerValue];
    }
    return textFontSize;
}

- (void)updateColorScheme {
    [ThemeManager decorateToolbar:self.toolbar];
    [ThemeManager updateStatusBarStyle];
    self.view.backgroundColor = [ThemeManager backgroundColor];
    self.webView.backgroundColor = [ThemeManager backgroundColor];
}

- (void)adjustFontForWebView {
    NSUInteger textFontSize = [MainViewController textFontSize];
    NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",
                          (unsigned long)textFontSize];
    [self.webView evaluateJavaScript:jsString completionHandler:^(id result, NSError *error) {
    }];
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL shouldEnable = YES;
    if ([alertView.title isEqualToString:@"Add Bookmark"]) {
        shouldEnable = [[alertView textFieldAtIndex:0].text length] > 0;
    }
    return shouldEnable;
}

// Open the external URL if anything but the cancel button is pressed.
- (void)alertView:(UIAlertView *)alertView
							didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Add Bookmark"]) {
        if (buttonIndex == 1) {
            BookmarksManager *bm = [BookmarksManager sharedInstance];
            self.bookmark.title = [alertView textFieldAtIndex:0].text;
            [bm addBookmark:self.bookmark];
        }
    }
    else if ([alertView.title isEqualToString:@"External Link"]) {
        if (buttonIndex > 0) {
                [[UIApplication sharedApplication] openURL:self.externalURL];
        }
    }
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
    if ([alertView.title isEqualToString:@"Add Bookmark"]) {
        [[alertView textFieldAtIndex:0] selectAll:nil];
    }
}

- (void)getBookmark:(void (^ _Nullable)(LocalBookmark * _Nullable))completionHandler {
    
    [self.webView evaluateJavaScript:@"String.prototype.stripHTML = function() {	"
     @"	var matchTag = /<(?:.|\\s)*?>/g;			"
     @"	var s = this.replace(matchTag, '');		"
     @"	var spaceRegexp = /\\s+/g;				"
     @"	return s.replace(spaceRegexp, ' ')		"
     @"};" completionHandler:^(id result, NSError *error) {
         [self.webView evaluateJavaScript:@"document.title" completionHandler:^(id result, NSError *error) {
             NSString *title = result;
             [self.webView evaluateJavaScript:@"location.href" completionHandler:^(id result, NSError *error) {
                 NSString *urlString = result;
                 NSString *location = [self URLStringToLocalContentPath:urlString];
                 [self.webView evaluateJavaScript:@"document.getElementById('H_tipitakaID').innerHTML.stripHTML()" completionHandler:^(id result, NSError *error) {
                     NSString *tipitakaID = result;
                     [self.webView evaluateJavaScript:@"scrollX" completionHandler:^(id result, NSError *error) {
                         NSInteger scrollX = [result integerValue];
                         [self.webView evaluateJavaScript:@"scrollY" completionHandler:^(id result, NSError *error) {
                             NSInteger scrollY = [result integerValue];
                             LocalBookmark *bookmark = [[[LocalBookmark alloc] initWithTitle:title
                                                                                    location:location
                                                                                     scrollX:scrollX
                                                                                     scrollY:scrollY] autorelease];
                             bookmark.note = tipitakaID;
                             completionHandler(bookmark);
                         }];
                     }];
                 }];
             }];
         }];
     }];
}


#pragma mark -
#pragma mark Bookmarks delegate methods

- (void)bookmarksController:(BookmarksTableController *)controller
		   selectedBookmark:(LocalBookmark *)bookmark {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.bmPopover dismissPopoverAnimated:YES];
		self.bmPopover = nil;
	} else
		[self dismissViewControllerAnimated:YES completion:nil];
	[self loadLocalBookmark:bookmark];
}

- (void)bookmarksControllerCancel:(BookmarksTableController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Toolbar actions

- (IBAction)home {
	[self loadLocalWebContent:@"index.html"];
}

- (IBAction)goBack {
    [self.webView setAlpha:self.startAlpha];
    [self.webView goBack];
    [UIView animateWithDuration:1.0f animations:^{
        [self.webView setAlpha:1.0f];
    } completion:^(BOOL finished) {
    }];
    
}

- (IBAction)goForward {
    [self.webView setAlpha:self.startAlpha];
    [self.webView goForward];
    [UIView animateWithDuration:1.0f animations:^{
        [self.webView setAlpha:0.5f];
    } completion:^(BOOL finished) {
    }];
}

- (IBAction)actionButton {
    if (self.bmPopover) {
        [self.bmPopover dismissPopoverAnimated:YES];
        self.bmPopover = nil;
    }
    
    self.actionSheet = [UIAlertController alertControllerWithTitle:@"Select Action" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([ThemeManager isNightMode]) {
        self.actionSheet.view.tintColor = [ThemeManager backgroundColor];
    }
    self.actionSheet.popoverPresentationController.barButtonItem = self.actionBarButtonItem;
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        // Cancel button tappped.
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:@"Add Bookmark" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self getBookmark:^(LocalBookmark *bookmark) {
            self.bookmark = bookmark;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Bookmark"
                                                            message:@"Enter a title for the bookmark"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Add", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField *inputField = [alert textFieldAtIndex:0];
            inputField.text = self.bookmark.title;
            [alert show];
        }];
    }]];
    
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:@"Open on Live Site" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self getBookmark:^(LocalBookmark *bookmark) {
            NSURL *liveURL = [NSURL URLWithString:[NSString
                                                   stringWithFormat:@"http://www.accesstoinsight.org%@",
                                                   bookmark.location]];
            [[UIApplication sharedApplication] openURL:liveURL];
        }];
    }]];
    
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:@"Random Sutta" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self loadLocalWebContent:@"random-sutta.html"];
    }]];
    
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:@"Random Article" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self loadLocalWebContent:@"random-article.html"];
    }]];
    
    // Present action sheet.
    [self presentViewController:self.actionSheet animated:YES completion:nil];
}

- (IBAction)showBookmarks {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if ([self.bmPopover isPopoverVisible]) {
			return;
		}
    }
	BookmarksTableController *btc = [[BookmarksTableController alloc]
									 initWithStyle:UITableViewStylePlain];
    btc.tableView.backgroundColor = [ThemeManager backgroundColor];
	btc.delegate = self;
	
	UINavigationController *nav = [[UINavigationController alloc]
								   initWithRootViewController:btc];
	nav.navigationBar.barStyle = UIBarStyleBlack;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		Class UIPopoverControllerClass = NSClassFromString(@"UIPopoverController");
		if (UIPopoverControllerClass != nil) {
            if (self.actionSheet) {
                [self.actionSheet dismissViewControllerAnimated:YES completion:^{
                }];
            }
            
			UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:nav];
			CGSize popoverSize = {300.0, 500.0};
			popover.delegate = self;
			popover.popoverContentSize = popoverSize;
			self.bmPopover = popover;
			[popover release];
			
			[self.bmPopover presentPopoverFromBarButtonItem:self.bmBarButtonItem
								   permittedArrowDirections:UIPopoverArrowDirectionAny
												   animated:YES];
		}
	} else {
		[self presentViewController:nav animated:YES completion:nil];
        [self.navigationController setNavigationBarHidden:YES animated:NO];
	}
	[btc release];
	[nav release];
}

- (IBAction)showSettings {
    SettingsViewController *controller = [[SettingsViewController alloc] init];
    controller.title = @"Settings";
    [self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

// Need to get rid of this. Too generic.
- (void)settingsControllerDidFinish {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (void)determineStartAlpha {
    self.startAlpha = [ThemeManager isNightMode] ? 0.0f : 1.0f;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return (interfaceOrientation == UIInterfaceOrientationPortrait
				|| interfaceOrientation == UIInterfaceOrientationLandscapeLeft
				|| interfaceOrientation == UIInterfaceOrientationLandscapeRight
				|| interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait
				|| interfaceOrientation == UIInterfaceOrientationLandscapeLeft
				|| interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark -  UI Popover Delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.bmPopover = nil;
}

- (void)didRotateFromInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation {
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    [self adjustFontForWebView];
}


- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
    [self saveLastLocation];
}

- (BOOL)prefersStatusBarHidden {
    return self.toolbarHidden;
}

- (void)saveLastLocation {
    [self getBookmark:^(LocalBookmark *lastLocationBookmark) {
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc]
                                      initForWritingWithMutableData:data] autorelease];
        [archiver encodeObject:lastLocationBookmark forKey:@"bookmark"];
        [archiver finishEncoding];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:data forKey:@"lastLocationBookmark"];
        [data release];
        [defaults synchronize];
    }];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.webView = nil;
	self.toolbar = nil;
	self.externalURL = nil;
	self.bmBarButtonItem = nil;
    self.actionBarButtonItem = nil;
	self.bmPopover = nil;
	[super viewDidUnload];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_actionSheet release];
    [bmBarButtonItem release];
    [actionBarButtonItem release];
	[webView release];
    [toolbar release];
	[externalURL release];
    [bmPopover release];
    [_bookmark release];
    
    [_topConstraint release];
    [_bottomConstraint release];
    [super dealloc];
}

@end
