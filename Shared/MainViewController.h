//
//  AtoIViewController.h
//  AtoI
//
//  Created by Robert Stone on 12/29/09.
//  Copyright Appmagination and Robert Stone 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/Webkit.h>

#import "EventInterceptWindow.h"
#import "BookmarksTableController.h"
#import "SearchViewController.h"

#define TEXT_FONT_SIZE_KEY @"fontSize"


@interface MainViewController : UIViewController <EventInterceptWindowDelegate,
		WKNavigationDelegate, BookmarksControllerDelegate,
        UIPopoverPresentationControllerDelegate, SearchViewDelegate, UITextFieldDelegate>
{
	WKWebView *webView;
	IBOutlet UIToolbar *toolbar;
	IBOutlet UIBarButtonItem *bmBarButtonItem;
    IBOutlet UIBarButtonItem *actionBarButtonItem;
	
	NSInteger rescrollX, rescrollY; // rescroll to here after webView load
	BOOL needRescroll;				// if this is YES
}

@property(nonatomic, retain) WKWebView *webView;
@property(nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *bmBarButtonItem;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *actionBarButtonItem;

- (IBAction)home;
- (IBAction)goBack;
- (IBAction)goForward;
- (IBAction)actionButton;
- (IBAction)showBookmarks;
- (IBAction)showSettings;
- (IBAction)showSearch;
- (void)saveLastLocation;

+ (NSInteger)textFontSize;


@end
