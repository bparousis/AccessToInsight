//
//  AtoIViewController.h
//  AtoI
//
//  Created by Robert Stone on 12/29/09.
//  Copyright Appmagination and Robert Stone 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EventInterceptWindow.h"
#import "InfoViewController.h"
#import "BookmarksTableController.h"


#define LOCAL_WEB_DATA_DIR	@"web_content"
#define SCREEN_CSS_PATH		@"css/screen.css"
#define IPHONE_CSS			@"iphone.css"
#define IPAD_CSS			@"ipad.css"


@interface MainViewController : UIViewController <EventInterceptWindowDelegate,
		UIWebViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate,
		InfoViewControllerDelegate, BookmarksControllerDelegate, UIPopoverControllerDelegate>
{
	IBOutlet UIWebView *webView;
	IBOutlet UIToolbar *toolbar;
	IBOutlet UIBarButtonItem *bmBarButtonItem;
    IBOutlet UIBarButtonItem *actionBarButtonItem;
			
	UIPopoverController *bmPopover;

	NSURL *externalURL;				// externalURL to load if "OK"
	
	NSInteger rescrollX, rescrollY; // rescroll to here after webView load
	BOOL needRescroll;				// if this is YES
}

@property(nonatomic, retain) IBOutlet UIWebView *webView;
@property(nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *bmBarButtonItem;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *actionBarButtonItem;

@property(nonatomic, retain) UIPopoverController *bmPopover;

@property(nonatomic, retain) NSURL *externalURL;

- (IBAction)home;
- (IBAction)actionButton;
- (IBAction)showBookmarks;
- (IBAction)pageDown;
- (IBAction)pageUp;
- (IBAction)showInfo;
- (void)saveLastLocation;

@end