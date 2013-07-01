//
//  AtoIViewController.m
//  AtoI
//
//  Created by Robert Stone on 12/29/09.
//  Copyright Appmagination and Robert Stone 2009. All rights reserved.
//

#import "MainViewController.h"
#import "InfoViewController.h"
#import "BookmarksManager.h"

@implementation MainViewController


@synthesize webView;
@synthesize toolbar;
@synthesize bmPopover;
@synthesize bmBarButtonItem;
@synthesize externalURL;


#pragma mark -
#pragma mark Event Intercept Window delegate stuff


- (void)toggleScreenDecorations {
	static BOOL toolbarHidden = NO;
	
	// toolbar
	[UIView beginAnimations:@"toolbar" context:nil];
	if (toolbarHidden) {
		toolbar.frame = CGRectOffset(toolbar.frame, 0, -toolbar.frame.size.height);
		toolbar.alpha = 1;
		toolbarHidden = NO;
	} else {
		toolbar.frame = CGRectOffset(toolbar.frame, 0, +toolbar.frame.size.height);
		toolbar.alpha = 0;
		toolbarHidden = YES;
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
	NSArray *a = [urlString componentsSeparatedByString:LOCAL_WEB_DATA_DIR];
	return [a objectAtIndex:1];
}


- (void)loadLocalWebContent:(NSString *)path {
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *fullPath = [NSString pathWithComponents:
						  [NSArray arrayWithObjects:resourcePath,
						   LOCAL_WEB_DATA_DIR, path, nil]];
	NSURL *url = [NSURL fileURLWithPath:fullPath];
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
		[NSString stringWithFormat: @"window.scrollTo(%d, %d);",
			scrollX, scrollY]];
}


- (void)scrollNumPages:(NSInteger)pages {
	NSInteger scrollY = [[self.webView
						  stringByEvaluatingJavaScriptFromString: @"scrollY"]
						 integerValue];
	NSInteger height = self.webView.frame.size.height;
	[self scrollToX:0 Y:(scrollY + (height * pages))];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if (needRescroll) {
		if (rescrollY || rescrollX)
			[self scrollToX:rescrollX Y:rescrollY];
		needRescroll = NO;
	}
}


// Open the external URL if anything but the cancel button is pressed.
- (void)alertView:(UIAlertView *)alertView
							didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([alertView.title isEqual:@"External Link"]) {
		if (buttonIndex > 0)
			[[UIApplication sharedApplication] openURL:self.externalURL];
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
		[self dismissModalViewControllerAnimated:YES];
	[self loadLocalBookmark:bookmark];
}


- (void)bookmarksControllerCancel:(BookmarksTableController *)controller {
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Toolbar actions


- (IBAction)home {
	[self loadLocalWebContent:@"index.html"];
}


- (IBAction)addButton {
	UIActionSheet *addSheet = [[UIActionSheet alloc]
							  initWithTitle:@"Select action for this page:"
								   delegate:self
						  cancelButtonTitle:@"Cancel"
					 destructiveButtonTitle:nil
						  otherButtonTitles:@"Add Bookmark", 
											@"Open on Live Site", nil];
	//addSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	[addSheet showFromToolbar:self.toolbar];
	[addSheet release];


}


- (void)actionSheet:(UIActionSheet *)actionSheet
		didDismissWithButtonIndex:(NSInteger)buttonIndex {
	
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

	if ([buttonTitle isEqual:@"Add Bookmark"]) {
		LocalBookmark *bookmark = [self getBookmark];
		BookmarksManager *bm = [BookmarksManager sharedInstance];
		[bm addBookmark:bookmark];		
	} else if ([buttonTitle isEqual:@"Open on Live Site"]) {
		LocalBookmark *bookmark = [self getBookmark];
		NSURL *liveURL = [NSURL URLWithString:[NSString
						stringWithFormat:@"http://www.accesstoinsight.org%@",
								bookmark.location]];
		[[UIApplication sharedApplication] openURL:liveURL];
	}
	/* Future features: email link, email text, email clipboard/selection */
}


- (IBAction)showBookmarks {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		if (self.bmPopover) {
			[self.bmPopover dismissPopoverAnimated:YES];
			self.bmPopover = nil;
			return;
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
			UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:btc];
			CGSize popoverSize = { 300.0, 500.0 };
			popover.delegate = self;
			popover.popoverContentSize = popoverSize;
			self.bmPopover = popover;
			[popover release];
			
			[self.bmPopover presentPopoverFromBarButtonItem:self.bmBarButtonItem
								   permittedArrowDirections:UIPopoverArrowDirectionAny
												   animated:YES];
		}
	} else {
		[self presentModalViewController:nav animated:YES];
	}
	[btc release];
	[nav release];
}


- (IBAction)showInfo {
	InfoViewController *controller;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		controller = [[InfoViewController alloc]
										initWithNibName:@"InfoViewController_iPad"
											bundle:nil];
	else
		controller = [[InfoViewController alloc]
					  initWithNibName:@"InfoViewController_iPhone"
					  bundle:nil];
		
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


// Need to get rid of this. Too generic.
- (void)infoViewControllerDidFinish {
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)pageDown {
	[self scrollNumPages:1];
}


- (IBAction)pageUp {
	[self scrollNumPages:-1];
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
		
		lastLocationBookmark = [unarchiver
										  decodeObjectForKey:@"bookmark"];
		[unarchiver finishDecoding];
		[unarchiver release];
	}
	
	if (lastLocationBookmark != nil) {
		[self loadLocalBookmark:lastLocationBookmark];
	} else {
		[self home];
	}	
	
	[super viewDidLoad];
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


- (void)didRotateFromInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation {
	[self.webView reload];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewWillDisappear:(BOOL)animated {
	LocalBookmark *lastLocationBookmark = [self getBookmark];
	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc]
								 initForWritingWithMutableData:data] autorelease];
	[archiver encodeObject:lastLocationBookmark forKey:@"bookmark"];
	[archiver finishEncoding];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:data forKey:@"lastLocationBookmark"];
	[data release];

	[super viewWillDisappear:animated];
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.webView = nil;
	self.toolbar = nil;
	self.externalURL = nil;
	self.bmBarButtonItem = nil;
	self.bmPopover = nil;
	[super viewDidUnload];
}


- (void)dealloc {
	[webView release];
	[externalURL release];
    [super dealloc];
}

@end
