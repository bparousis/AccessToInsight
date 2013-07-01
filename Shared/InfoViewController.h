//
//  InfoViewController.h
//  AtoI
//
//  Created by Robert Stone on 12/29/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol InfoViewControllerDelegate
- (void)infoViewControllerDidFinish;
@end


@interface InfoViewController : UIViewController {
	IBOutlet id <InfoViewControllerDelegate> delegate;
}

@property(nonatomic, assign) IBOutlet id <InfoViewControllerDelegate> delegate;

- (IBAction)done;
- (IBAction)linkToATI;
- (IBAction)linkToAppmagination;
- (IBAction)mailToAppmagination;
- (IBAction)mailToATI;

@end
