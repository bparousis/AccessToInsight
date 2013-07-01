//
//  AtoIAppDelegate.m
//  AtoI
//
//  Created by Robert Stone on 12/29/09.
//  Copyright Appmagination and Robert Stone 2009. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@implementation AppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    

	application.statusBarStyle = UIStatusBarStyleBlackTranslucent;
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	
}


-(void)applicationWillTerminate:(UIApplication *)application {
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
