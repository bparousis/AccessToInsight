//
//  BookmarksController.m
//  AtoI
//
//  Created by Robert Stone on 12/30/09.
//  Copyright 2009 Appmagination and Robert Stone. All rights reserved.
//

#import "BookmarksTableController.h"
#import "BookmarksManager.h"
#import "ThemeManager.h"

@interface BookmarksTableController()

@property(nonatomic, assign) NSUInteger editBookmarkIndex;
@property(nonatomic, retain) UIAlertAction *doneEditAction;

@end

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
    
    if ([ThemeManager isNightMode]) {
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor whiteColor];
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
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
    LocalBookmark *bookmark = [bm bookmarkAtIndex:[indexPath row]];
    if (tableView.isEditing) {
        self.editBookmarkIndex = [indexPath row];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Edit Bookmark" message:@"Enter a title for the bookmark" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = bookmark.title;
            [textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        self.doneEditAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            BookmarksManager *bm = [BookmarksManager sharedInstance];
            LocalBookmark *bookmark = [bm bookmarkAtIndex:self.editBookmarkIndex];
            bookmark.title = [alert textFields][0].text;
            [bm save];
            [self.tableView reloadData];
            
        }];
        [alert addAction:self.doneEditAction];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        [self.delegate bookmarksController:self
                          selectedBookmark:bookmark];
    }
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

-(void)textDidChange:(UITextField *)textField {
    self.doneEditAction.enabled = textField.text.length > 0;
}

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
    self.tableView.backgroundColor = [ThemeManager backgroundColor];
    self.tableView.allowsSelectionDuringEditing = YES;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *cancelButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(cancel)];
        self.navigationItem.leftBarButtonItem = cancelButtonItem;
        [cancelButtonItem release];
    }
}


- (BOOL)shouldAutorotate {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return (interfaceOrientation == UIInterfaceOrientationPortrait
			|| interfaceOrientation == UIInterfaceOrientationLandscapeLeft
			|| interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [_doneEditAction release];
    [super dealloc];
}


@end

