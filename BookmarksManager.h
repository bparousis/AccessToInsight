//
//  BookmarksManager.h
//  AtoI
//
//  Created by Robert Stone on 12/30/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LocalBookmark.h"

#define kDefaultBookmarksPlistName	@"DefaultBookmarks"
#define kBookmarksArchiveFilename	@"LocalBookmarks"
#define kBookmarksKey				@"bookmarks"


@interface BookmarksManager : NSObject {
	NSMutableArray *bookmarks;
}

@property(nonatomic, retain) NSArray *bookmarks;

+ (BookmarksManager *)sharedInstance;

- (void)save;
- (void)load;

- (NSUInteger)getCount;
- (LocalBookmark *)bookmarkAtIndex:(NSUInteger)index;
- (void)addBookmark:(LocalBookmark *)bookmark;
- (void)deleteBookmarkAtIndex:(NSUInteger)index;
- (void)moveBookmarkAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end
