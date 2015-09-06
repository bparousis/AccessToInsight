//
//  AtoIViewController.m
//  AtoI
//
//  Created by Robert Stone on 12/29/09.
//  Copyright Appmagination and Robert Stone 2009. All rights reserved.
//

#import "MainViewController.h"
#import "InfoViewController.h"
#import "SettingsViewController.h"
#import "BookmarksManager.h"

#define TEXT_FONT_SIZE_KEY @"fontSize"

@interface MainViewController()

@property(nonatomic, retain) UIActionSheet *actionSheet;
@property(nonatomic, assign) BOOL toolbarHidden;
@property(nonatomic, retain) LocalBookmark *bookmark;

@end

@implementation MainViewController

@synthesize webView;
@synthesize toolbar;
@synthesize bmPopover;
@synthesize bmBarButtonItem;
@synthesize externalURL;
@synthesize actionBarButtonItem;

#pragma mark -
#pragma mark Event Intercept Window delegate stuff

- (void)toggleScreenDecorations {
	// toolbar
	[UIView beginAnimations:@"toolbar" context:nil];
	if (self.toolbarHidden) {
		toolbar.frame = CGRectOffset(toolbar.frame, 0, -toolbar.frame.size.height);
		toolbar.alpha = 1;
		self.toolbarHidden = NO;
	} else {
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

/*
 * Open external links in Safari.
 */
- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
    navigationType:(UIWebViewNavigationType)navigationType {

	if (navigationType == UIWebViewNavigationTypeOther)
		return YES;

	NSURL *url = [request URL];
	
	if ([[url scheme] isEqual:@"file"]) {
		return YES;
	}
	
	if ([[UIApplication sharedApplication] canOpenURL:url] == NO) {
		return NO;
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
	
	return NO;
}

- (void)scrollToX:(NSInteger)scrollX Y:(NSInteger)scrollY {
	[self.webView stringByEvaluatingJavaScriptFromString:
		[NSString stringWithFormat: @"window.scrollTo(%ld, %ld);",
			(long)scrollX, (long)scrollY]];
}


- (void)scrollNumPages:(NSInteger)pages {
	NSInteger scrollY = [[self.webView
						  stringByEvaluatingJavaScriptFromString: @"scrollY"]
						 integerValue];
	NSInteger height = self.webView.frame.size.height;
	[self scrollToX:0 Y:(scrollY + (height * pages))];
}

- (NSInteger)textFontSize {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *textFontSizeNum = [userDefaults objectForKey:TEXT_FONT_SIZE_KEY];
    NSUInteger textFontSize = 100;
    if (textFontSizeNum) {
        textFontSize = [textFontSizeNum integerValue];
    }
    return textFontSize;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self adjustFontForWebView];
    
    if (needRescroll) {
		if (rescrollY || rescrollX)
			[self scrollToX:rescrollX Y:rescrollY];
		needRescroll = NO;
	}
}

- (void)adjustFontForWebView {
    NSUInteger textFontSize = [self textFontSize];
    NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",
                          (unsigned long)textFontSize];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
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

- (LocalBookmark *)getBookmark {
	
	// Define html stripping function for current page.
    [self.webView stringByEvaluatingJavaScriptFromString:
     @"String.prototype.stripHTML = function() {	"
     @"	var matchTag = /<(?:.|\\s)*?>/g;			"
     @"	var s = this.replace(matchTag, '');		"
     @"	var spaceRegexp = /\\s+/g;				"
     @"	return s.replace(spaceRegexp, ' ')		"
     @"};"];
	
	NSString *title = [self.webView
					   stringByEvaluatingJavaScriptFromString:@"document.title"];
	NSString *urlString = [self.webView
						   stringByEvaluatingJavaScriptFromString:@"location.href"];	
	NSString *location = [self URLStringToLocalContentPath:urlString];
	NSString *tipitakaID = [self.webView stringByEvaluatingJavaScriptFromString:
                                   @"document.getElementById('H_tipitakaID').innerHTML.stripHTML()"];
	NSInteger scrollX = [[self.webView
						  stringByEvaluatingJavaScriptFromString: @"scrollX"]
						 integerValue];
	NSInteger scrollY = [[self.webView
						  stringByEvaluatingJavaScriptFromString: @"scrollY"]
						 integerValue];
	LocalBookmark *bookmark = [[[LocalBookmark alloc] initWithTitle:title 
										location:location 
										 scrollX:scrollX 
										 scrollY:scrollY] autorelease];
	bookmark.note = tipitakaID;
	return bookmark;
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

- (IBAction)actionButton {
    if (!self.actionSheet) {
        if (self.bmPopover) {
            [self.bmPopover dismissPopoverAnimated:YES];
            self.bmPopover = nil;
        }
        
        self.actionSheet = [[[UIActionSheet alloc]
                            initWithTitle:@"Select action for this page:"
                            delegate:self
                            cancelButtonTitle:@"Cancel"
                            destructiveButtonTitle:nil
                            otherButtonTitles:@"Add Bookmark",
                            @"Open on Live Site", @"Random Sutta", @"Random Article", nil] autorelease];
        //addSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [self.actionSheet showFromBarButtonItem:self.actionBarButtonItem animated:YES];
        }
        else {
            [self.actionSheet showFromToolbar:self.toolbar];
        }
    }
}


- (void)actionSheet:(UIActionSheet *)actionSheet
		didDismissWithButtonIndex:(NSInteger)buttonIndex {
	
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

	if ([buttonTitle isEqual:@"Add Bookmark"]) {
		self.bookmark = [self getBookmark];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Bookmark"
                                                        message:@"Enter a title for the bookmark"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Add", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *inputField = [alert textFieldAtIndex:0];
        inputField.text = self.bookmark.title;
        [alert show];
	}
    else if ([buttonTitle isEqual:@"Open on Live Site"]) {
		LocalBookmark *bookmark = [self getBookmark];
		NSURL *liveURL = [NSURL URLWithString:[NSString
						stringWithFormat:@"http://www.accesstoinsight.org%@",
								bookmark.location]];
		[[UIApplication sharedApplication] openURL:liveURL];
	}
    else if ([buttonTitle isEqual:@"Random Sutta"]) {
        [self loadLocalWebContent:@"random-sutta.html"];
    }
    else if ([buttonTitle isEqual:@"Random Article"]) {
        [self loadLocalWebContent:@"random-article.html"];
    }
    
    self.actionSheet = nil;
	/* Future features: email link, email text, email clipboard/selection */
}


- (IBAction)showBookmarks {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if ([self.bmPopover isPopoverVisible]) {
			return;
		}
    }
	BookmarksTableController *btc = [[BookmarksTableController alloc]
									 initWithStyle:UITableViewStylePlain];
	btc.delegate = self;
	
	UINavigationController *nav = [[UINavigationController alloc]
								   initWithRootViewController:btc];
	nav.navigationBar.barStyle = UIBarStyleBlack;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		Class UIPopoverControllerClass = NSClassFromString(@"UIPopoverController");
		if (UIPopoverControllerClass != nil) {
            if (self.actionSheet) {
                [self.actionSheet dismissWithClickedButtonIndex:2 animated:YES];
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


- (IBAction)showInfo {
    SettingsViewController *controller = [[SettingsViewController alloc] init];
    controller.title = @"About";
//    controller.navigationItem.rightBarButtonItem =  [[[UIBarButtonItem alloc] initWithTitle:@"Done"
//                                                                                     style:UIBarButtonItemStyleDone target:self
//                                                                                    action:@selector(settingsControllerDidFinish)] autorelease];
    [self.navigationController pushViewController:controller animated:YES];
	[controller release];
}


// Need to get rid of this. Too generic.
- (void)settingsControllerDidFinish {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)increaseTextFontSize:(BOOL)increase
{
    NSUInteger textFontSize = [self textFontSize];
    
    if (increase) {
        textFontSize = (textFontSize < 160) ? textFontSize +5 : textFontSize;
    }
    else {
        textFontSize = (textFontSize > 50) ? textFontSize -5 : textFontSize;
    }
 
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithInteger:textFontSize] forKey:TEXT_FONT_SIZE_KEY];
    [userDefaults synchronize];
    
    [self adjustFontForWebView];
}

- (IBAction)decreaseFont {
    [self increaseTextFontSize:NO];
}

- (IBAction)increaseFont {
    [self increaseTextFontSize:YES];
}

- (void)writeScreenCSS: (NSString *)cssText {
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *fullPath = [NSString pathWithComponents:
						  [NSArray arrayWithObjects:resourcePath,
						   LOCAL_WEB_DATA_DIR, SCREEN_CSS_PATH, nil]];
	
	NSError *err;
	
	[cssText writeToFile:fullPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
}


#pragma mark -
#pragma mark Standard methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
	// Load the last page the user was viewing.
	// Unfortunately I don't know of a way to save and load the history.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *data = [defaults objectForKey:@"lastLocationBookmark"];

	LocalBookmark *lastLocationBookmark = nil;
	
	switch (UI_USER_INTERFACE_IDIOM()) {
		case UIUserInterfaceIdiomPad:
			[self writeScreenCSS:@"@import url('" IPAD_CSS @"');\n"];
			break;
		case UIUserInterfaceIdiomPhone:
		default:
			[self writeScreenCSS:@"@import url('" IPHONE_CSS @"');\n"];
			break;
	} 
	
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

- (void)didRotateFromInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation {
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
    LocalBookmark *lastLocationBookmark = [self getBookmark];
	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc]
                                  initForWritingWithMutableData:data] autorelease];
	[archiver encodeObject:lastLocationBookmark forKey:@"bookmark"];
	[archiver finishEncoding];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:data forKey:@"lastLocationBookmark"];
	[data release];
    [defaults synchronize];
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
    [_actionSheet release];
    [bmBarButtonItem release];
    [actionBarButtonItem release];
	[webView release];
    [toolbar release];
	[externalURL release];
    [bmPopover release];
    [_bookmark release];
    [super dealloc];
}

@end
