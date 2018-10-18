//
//  AboutViewController.h
//  AccessToInsight
//
//  Created by Bill Parousis on 2013-07-11.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <WebKit/Webkit.h>

@interface AboutViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate, WKNavigationDelegate>
@end
