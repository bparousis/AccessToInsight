//
//  BookmarksController.h
//  AtoI
//
//  Created by Robert Stone on 12/30/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LocalBookmark.h"

#define kBookmarkCellID @"BookmarkCellID"

@protocol BookmarksControllerDelegate;


@interface BookmarksTableController : UITableViewController {
	id <BookmarksControllerDelegate, UIAlertViewDelegate> delegate;
}

@property(nonatomic, assign) id <BookmarksControllerDelegate> delegate;

@end


@protocol BookmarksControllerDelegate 

- (void)bookmarksController:(BookmarksTableController *)controller
		   selectedBookmark:(LocalBookmark *)bookmark;

- (void)bookmarksControllerCancel:(BookmarksTableController *)controller;

@end