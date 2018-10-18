//
//  SearchViewController.h
//  AccessToInsight
//
//  Created by Bill Parousis on 2017-06-25.
//
//

#import <UIKit/UIKit.h>


@protocol SearchViewDelegate;

@interface SearchViewController : UITableViewController<UISearchResultsUpdating, UISearchBarDelegate>

//@property(nonatomic, retain) UITableView *tableView;
@property(nonatomic, retain) UISearchController *searchController;
@property(nonatomic, assign) id<SearchViewDelegate> searchDelegate;

@end

@protocol SearchViewDelegate

- (void)loadPage:(NSString *)filePath;
- (void)searchViewControllerCancel:(SearchViewController *)controller;

@end
