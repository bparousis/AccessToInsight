//
//  CustomUIWebView.h
//  AccessToInsight
//
//  Created by Robert Stone on 1/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol TouchInterceptViewDelegate

- (void)doubleTap;

@end


@interface TouchInterceptView : UIView	{
	id <TouchInterceptViewDelegate> delegate;
}

@property(nonatomic, assign) id <TouchInterceptViewDelegate> delegate;

@end
