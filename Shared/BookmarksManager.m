//
//  BookmarksManager.m
//  AtoI
//
//  Created by Robert Stone on 12/30/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import "BookmarksManager.h"


@implementation BookmarksManager

@synthesize bookmarks;

#pragma mark -
#pragma mark Standard Methods


- (id)init {
    if (self = [super init]) {
		[self load];
    }
    return self;
}

- (void)dealloc {
	[bookmarks release];
	[super dealloc];
}

+ (BookmarksManager *)sharedInstance {
	static BookmarksManager *singleInstance = nil;
	
	if (!singleInstance) {
		singleInstance = [[BookmarksManager alloc] init];
	}
	
	return singleInstance;
}


#pragma mark -
#pragma mark Data load/save methods


- (NSString *)archiveFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
														 NSUserDomainMask,
														 YES);
	NSString *documentsDir = [paths objectAtIndex:0];
	return [documentsDir
			stringByAppendingPathComponent:kBookmarksArchiveFilename];
}


/*
 * Load bookmarks from archive file.
 */
- (void)load {
	// Attempt to load bookmarks from file.
	NSData *data = [[NSMutableData alloc]
					initWithContentsOfFile:[self archiveFilePath]];
	if (data) {
		// If there's a file there, load it.
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]
										 initForReadingWithData:data];
		
		self.bookmarks = [NSMutableArray 
						  arrayWithArray:[unarchiver
										  decodeObjectForKey:kBookmarksKey]];
		[unarchiver finishDecoding];
		[unarchiver release];
		[data release];
	} else {
		// If not, load the default set of bookmarks.
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *plistPath = [bundle pathForResource:kDefaultBookmarksPlistName
											   ofType:@"plist"];
		NSArray *defaultBookmarks = [[NSArray alloc]
							  initWithContentsOfFile:plistPath];
		NSMutableArray *newBookmarks = [[NSMutableArray alloc] init];
		for (NSDictionary *dict in defaultBookmarks) {
			LocalBookmark *bm = [[LocalBookmark alloc]
			  initWithTitle:[dict objectForKey:@"title"]
				   location:[dict objectForKey:@"location"]
					scrollX:[[dict objectForKey:@"scrollX"] integerValue]
					scrollY:[[dict objectForKey:@"scrollY"] integerValue]];
			bm.note = [dict objectForKey:@"note"];
			[newBookmarks addObject:bm];
			[bm release];
		}
		self.bookmarks = newBookmarks;
		[defaultBookmarks release];
		[newBookmarks release];
	}
}


/*
 * Save bookmarks to archive file.
 */
- (void)save {
	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]
								 initForWritingWithMutableData:data];
	[archiver encodeObject:bookmarks forKey:kBookmarksKey];
	[archiver finishEncoding];
	[data writeToFile:[self archiveFilePath] atomically:YES];
	[archiver release];
	[data release];
}


#pragma mark -
#pragma mark Data access methods

- (NSUInteger)getCount {
	return [bookmarks count];
}

- (LocalBookmark *)bookmarkAtIndex:(NSUInteger)index {
	return (LocalBookmark *)[bookmarks objectAtIndex:index];
}


- (void)addBookmark:(LocalBookmark *)bookmark {
	[bookmarks addObject:bookmark];
    [self save];
}

- (void)deleteBookmarkAtIndex:(NSUInteger)index {
	[bookmarks removeObjectAtIndex:index];	
}


- (void)moveBookmarkAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
	LocalBookmark *bookmarkToMove = [bookmarks objectAtIndex:fromIndex];
	[bookmarkToMove retain];
	[bookmarks removeObjectAtIndex:fromIndex];
	[bookmarks insertObject:bookmarkToMove atIndex:toIndex];
	[bookmarkToMove release];
}

@end