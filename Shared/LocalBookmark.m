//
//  LocalBookmark.m
//  AtoI
//
//  Created by Robert Stone on 12/30/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import "LocalBookmark.h"


@implementation LocalBookmark

@synthesize title, location, note;
@synthesize scrollX, scrollY;


- (id)initWithTitle:(NSString *)ititle location:(NSString *)ilocation
			scrollX:(NSInteger)iscrollX scrollY:(NSInteger)iscrollY {
	if (self = [super init]) {
		self.title = ititle;
		self.location = ilocation;
		self.scrollX = iscrollX;
		self.scrollY = iscrollY;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		self.title = [decoder decodeObjectForKey:@"title"];
		self.location = [decoder decodeObjectForKey:@"location"];
		self.note = [decoder decodeObjectForKey:@"note"];
		self.scrollX = [decoder decodeIntegerForKey:@"scrollX"];
		self.scrollY = [decoder decodeIntegerForKey:@"scrollY"];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:title forKey:@"title"];
	[encoder encodeObject:location forKey:@"location"];
	[encoder encodeObject:note forKey:@"note"];
	[encoder encodeInteger:scrollX forKey:@"scrollX"];
	[encoder encodeInteger:scrollY forKey:@"scrollY"];
}


- (void)dealloc {
	[title release];
	[location release];
	[note release];
	[super dealloc];
}

@end
