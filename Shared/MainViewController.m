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
#import "SearchViewController.h"

@interface MainViewController()

@property(nonatomic, retain) UIAlertController *actionSheet;
@property(nonatomic, assign) BOOL toolbarHidden;
@property(nonatomic, retain) LocalBookmark *bookmark;
@property(nonatomic, assign) CGFloat startAlpha;
@property(nonatomic, retain) UIAlertAction *doneAddBookmark;

@property(nonatomic, retain) NSLayoutConstraint *topConstraint;
@property(nonatomic, retain) NSLayoutConstraint *bottomConstraint;

@end

@implementation MainViewController

@synthesize webView;
@synthesize toolbar;
@synthesize bmBarButtonItem;
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
    
    UITapGestureRecognizer *tapGesture = [[[UITapGestureRecognizer alloc]
                                           initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 2;
    [self.webView addGestureRecognizer:tapGesture];

    [self determineStartAlpha];
    self.webView.opaque = NO;
    [self updateColorScheme];
    [self.view addSubview:self.webView];
    
    if (@available(iOS 11, *)) {
        UILayoutGuide * guide = self.view.safeAreaLayoutGuide;
        [self.webView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor].active = YES;
        [self.webView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor].active = YES;
        self.topConstraint = [self.webView.topAnchor constraintEqualToAnchor:guide.topAnchor];
        self.bottomConstraint = [self.webView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor];
    } else {
        UILayoutGuide *margins = self.view.layoutMarginsGuide;
        [self.webView.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor].active = YES;
        [self.webView.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor].active = YES;
        self.topConstraint = [self.webView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor];
        self.bottomConstraint = [self.webView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor];
    }
    self.topConstraint.active = YES;
    self.bottomConstraint.constant = -44.0f;
    self.bottomConstraint.active = YES;
    [self.view layoutIfNeeded];
    
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)handleTapGesture:(UITapGestureRecognizer *) recognizer {
    [self toggleScreenDecorations];
}

#pragma mark -
#pragma mark Event Intercept Window delegate stuff

- (void)toggleScreenDecorations {
    // toolbar
    self.toolbarHidden = !self.toolbarHidden;
    [UIView beginAnimations:@"toolbar" context:nil];
    if (self.toolbarHidden == NO) {
        self.bottomConstraint.constant = -44.0f;
        toolbar.hidden = false;

    } else {
        self.bottomConstraint.constant = 0.0f;
        toolbar.hidden = true;
    }
    [self.view layoutIfNeeded];
    [UIView commitAnimations];

    [UIView animateWithDuration:0.25 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

#pragma mark -
#pragma mark Web view stuff


- (NSString *)URLStringToLocalContentPath:(NSString *)urlString {
	NSArray *urlArray = [urlString componentsSeparatedByString:LOCAL_WEB_DATA_DIR];
    return ([urlArray count] >= 2) ? [urlArray objectAtIndex:1] : nil;
}


- (void)loadLocalWebContent:(NSString *)path {
    NSRange hashRange = [path rangeOfString:@"#" options:NSBackwardsSearch];
    if (hashRange.location != NSNotFound) {
        path = [path substringToIndex:hashRange.location];
    }
    
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *readAccessPath = [NSString pathWithComponents:
                                [NSArray arrayWithObjects:resourcePath,
                                 LOCAL_WEB_DATA_DIR, nil]];
	NSString *fullPath = [NSString pathWithComponents:
						  [NSArray arrayWithObjects:resourcePath,
						   LOCAL_WEB_DATA_DIR, path, nil]];
    NSURL *url = [NSURL fileURLWithPath:fullPath];
    NSURL *readAccessURL = [NSURL fileURLWithPath:readAccessPath];
    
    [self.webView loadFileURL:url allowingReadAccessToURL:readAccessURL];
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
    
    [[UIApplication sharedApplication] openURL:url];
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
    self.view.backgroundColor = [ThemeManager backgroundColor];
    self.webView.backgroundColor = [ThemeManager backgroundColor];
    self.navigationController.navigationBar.barStyle = [ThemeManager isNightMode] ? UIBarStyleBlackTranslucent : UIBarStyleDefault;
}

- (void)adjustFontForWebView {
    NSUInteger textFontSize = [MainViewController textFontSize];
    NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",
                          (unsigned long)textFontSize];
    [self.webView evaluateJavaScript:jsString completionHandler:^(id result, NSError *error) {
    }];
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
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Bookmark"
                                                                           message:@"Enter a title for the bookmark"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.text = self.bookmark.title;
                textField.delegate = self;
                [textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
            }];
            self.doneAddBookmark = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *bookmarkTitle = [alert textFields][0].text;
                BookmarksManager *bm = [BookmarksManager sharedInstance];
                self.bookmark.title = bookmarkTitle;
                [bm addBookmark:self.bookmark];
            }];
            [alert addAction:self.doneAddBookmark];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            
            [self presentViewController:alert animated:YES completion:nil];
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

-(void)textDidChange:(UITextField *)textField {
    self.doneAddBookmark.enabled = textField.text.length > 0;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField selectAll:nil];
}

- (IBAction)showBookmarks {
	BookmarksTableController *btc = [[BookmarksTableController alloc]
									 initWithStyle:UITableViewStylePlain];
	btc.delegate = self;
	
	UINavigationController *nav = [[UINavigationController alloc]
								   initWithRootViewController:btc];
    nav.navigationBar.barStyle = [ThemeManager isNightMode] ? UIBarStyleBlackTranslucent : UIBarStyleDefault;
    
    nav.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:nav animated:YES completion:nil];
    
    // configure the Popover presentation controller
    UIPopoverPresentationController *popController = [nav popoverPresentationController];
    
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.bmBarButtonItem;
    popController.delegate = self;
	
	[btc release];
	[nav release];
}

- (IBAction)showSettings {
    SettingsViewController *controller = [[SettingsViewController alloc] init];
    controller.title = @"Settings";
    [self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (IBAction)showSearch {
    SearchViewController *controller = [[[SearchViewController alloc] init] autorelease];
    controller.searchDelegate = self;
    controller.title = @"Search";
    
    UINavigationController *nav = [[[UINavigationController alloc]
                                    initWithRootViewController:controller] autorelease];
    nav.navigationBar.barStyle = [ThemeManager isNightMode] ? UIBarStyleBlackTranslucent : UIBarStyleDefault;
    [self presentViewController:nav animated:YES completion:nil];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)loadPage:(NSString *)filePath {
    [self loadLocalWebContent:filePath];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)searchViewControllerCancel:(SearchViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Need to get rid of this. Too generic.
- (void)settingsControllerDidFinish {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (void)determineStartAlpha {
    self.startAlpha = [ThemeManager isNightMode] ? 0.0f : 1.0f;
}

- (BOOL)shouldAutorotate {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
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

-(UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [ThemeManager isNightMode] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_actionSheet release];
    [bmBarButtonItem release];
    [actionBarButtonItem release];
	[webView release];
    [toolbar release];
    [_bookmark release];
    [_doneAddBookmark release];
    
    [_topConstraint release];
    [_bottomConstraint release];
    [super dealloc];
}

@end
