//
//  InfoViewController.m
//  AtoI
//
//  Created by Robert Stone on 12/29/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import "InfoViewController.h"


@implementation InfoViewController

@synthesize delegate;


- (void)openURL:(NSString *)urlString {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction)linkToATI {
	[self openURL:@"http://www.accesstoinsight.org/"];
}

- (IBAction)linkToAppmagination {
	[self openURL:@"http://www.appmagination.com/"];
}

- (IBAction)mailToAppmagination {
	[self openURL:@"mailto:support@appmagination.com?"
	              @"subject=Question%20about%20ATI%20iPhone%20App"];
}

- (IBAction)mailToATI {
	[self openURL:@"mailto:john@accesstoinsight.org?"
				  @"subject=Question%20about%20content%20of%20ATI%20iPhone%20App"];
}

- (IBAction)done {
	[self.delegate infoViewControllerDidFinish];	
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		self.modalPresentationStyle = UIModalPresentationFormSheet;
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
/*	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return (interfaceOrientation == UIInterfaceOrientationPortrait
			|| interfaceOrientation == UIInterfaceOrientationLandscapeLeft
			|| interfaceOrientation == UIInterfaceOrientationLandscapeRight
			|| interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
	else */
		return interfaceOrientation == UIInterfaceOrientationPortrait;

}

- (void)dealloc {
    [super dealloc];
}


@end
