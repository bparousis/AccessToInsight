//
//  AppDelegate.h
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-10-10.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MainViewController *viewController;

@end
