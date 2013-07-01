//
//  EventInterceptWindow.h
//  AccessToInsight
//
//  Created by Robert Stone on 1/1/10.
//  Copyright 2010 Appmagination and Robert Stone. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol EventInterceptWindowDelegate
- (BOOL)interceptEvent:(UIEvent *)event; // return YES if event handled
@end


@interface EventInterceptWindow : UIWindow {
	// It would appear that using the variable name 'delegate' in any UI Kit
	// subclass is a really bad idea because it can occlude the same name in a
	// superclass and silently break things like autorotation.
	id <EventInterceptWindowDelegate> eventInterceptDelegate;
}

@property(nonatomic, assign)
	id <EventInterceptWindowDelegate> eventInterceptDelegate;

@end
