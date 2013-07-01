//
//  LocalBookmark.h
//  AtoI
//
//  Created by Robert Stone on 12/30/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LocalBookmark : NSObject <NSCoding> {
	NSString *title;
	NSString *location;
	NSString *note;
	NSInteger scrollX, scrollY;
}

@property(nonatomic, retain) NSString *title, *location, *note;
@property(nonatomic, assign) NSInteger scrollX, scrollY;

- (id)initWithTitle:(NSString *)title location:(NSString *)location
			scrollX:(NSInteger)scrollX scrollY:(NSInteger)scrollY;

@end
