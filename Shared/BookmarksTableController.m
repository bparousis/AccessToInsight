//
//  BookmarksController.m
//  AtoI
//
//  Created by Robert Stone on 12/30/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import "BookmarksTableController.h"
#import "BookmarksManager.h"

@implementation BookmarksTableController

@synthesize delegate;


#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[BookmarksManager sharedInstance] getCount];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = kBookmarkCellID;
    
    UITableViewCell *cell = [tableView
							 dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleSubtitle
				 reuseIdentifier:CellIdentifier] autorelease];
    }
    
	NSUInteger row = [indexPath row];
	LocalBookmark *bookmark = [[BookmarksManager sharedInstance]
							   bookmarkAtIndex:row];
	cell.textLabel.text = bookmark.title;
	cell.detailTextLabel.text = bookmark.note;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView
		didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BookmarksManager *bm = [BookmarksManager sharedInstance];
	[self.delegate bookmarksController:self
					  selectedBookmark:[bm bookmarkAtIndex:[indexPath row]]];
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
			commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
			 forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		BookmarksManager *bm = [BookmarksManager sharedInstance];
		[bm deleteBookmarkAtIndex:[indexPath row]];
		// MUST do this afterwards or count will be wrong and exception will
		// be thrown.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						 withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // not supported
    }
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView
		moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
			   toIndexPath:(NSIndexPath *)toIndexPath {
	BookmarksManager *bm = [BookmarksManager sharedInstance];
	[bm moveBookmarkAtIndex:[fromIndexPath row]
					toIndex:[toIndexPath row]];
}


#pragma mark -
#pragma mark Nav bar actions


- (void)cancel {
	[self.delegate bookmarksControllerCancel:self];
}


#pragma mark -
#pragma mark Standard methods


/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 if (self = [super initWithStyle:style]) {
 }
 return self;
 }
 */


- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Bookmarks";
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	UIBarButtonItem *cancelButtonItem =
	[[UIBarButtonItem alloc] initWithTitle:@"Close"
									 style:UIBarButtonItemStyleDone
									target:self
									action:@selector(cancel)];
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
	[cancelButtonItem release];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait
			|| interfaceOrientation == UIInterfaceOrientationLandscapeLeft
			|| interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

