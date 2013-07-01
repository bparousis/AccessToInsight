//
//  AppDelegate_iPhone.h
//  AccessToInsight-Universal
//
//  Created by Robert Stone on 10/2/10.
//  Copyright 2010 Appmagination. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface AppDelegate_iPhone : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MainViewController *viewController;

@end