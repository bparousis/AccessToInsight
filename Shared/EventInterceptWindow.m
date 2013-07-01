//
//  EventInterceptWindow.m
//  AccessToInsight
//
//  Created by Robert Stone on 1/1/10.
//  Copyright 2010 Appmagination and Robert Stone. All rights reserved.
//

#import "EventInterceptWindow.h"


@implementation EventInterceptWindow


@synthesize eventInterceptDelegate;


- (void)sendEvent:(UIEvent *)event {
	if ([eventInterceptDelegate interceptEvent:event] == NO)
		[super sendEvent:event];
}


@end
