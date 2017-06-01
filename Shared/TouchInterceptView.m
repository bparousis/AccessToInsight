//
//  CustomUIWebView.m
//  AccessToInsight
//
//  Created by Robert Stone on 1/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TouchInterceptView.h"


@implementation TouchInterceptView


@synthesize delegate;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSInteger tapCount = [[touches anyObject] tapCount];
    if (tapCount >= 2) {
		[self.delegate doubleTap];
    }
	[super touchesBegan:touches withEvent:event];
	[self.nextResponder touchesBegan:touches withEvent:event];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	[self.nextResponder touchesEnded:touches withEvent:event];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event];
	[self.nextResponder touchesMoved:touches withEvent:event];
}


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}


- (void)dealloc {
    [super dealloc];
}


@end
