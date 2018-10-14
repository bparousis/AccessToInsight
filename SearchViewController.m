//
//  SearchViewController.m
//  AccessToInsight
//
//  Created by Dev on 2017-06-25.
//
//

#import "SearchViewController.h"
#import "SearchEngine.h"
#import "ThemeManager.h"

@interface SearchViewController ()

@property(nonatomic, retain) SearchEngine *searchEngine;
@property(nonatomic, retain) NSArray *tableData;
@property(nonatomic, assign) BOOL showRecentSearches;
@property(nonatomic, retain) NSTimer *searchTimer;
@property(nonatomic, assign) BOOL isSearching;
@property(nonatomic, retain) UIActivityIndicatorView *searchingIndicator;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isSearching = NO;
    self.searchTimer = nil;
    self.showRecentSearches = YES;
    self.tableView.backgroundColor = [ThemeManager backgroundColor];
    // Do any additional setup after loading the view.
    UIBarButtonItem *cancelButtonItem =
    [[[UIBarButtonItem alloc] initWithTitle:@"Close"
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(cancel)] autorelease];
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *recentSearches = [userDefaults arrayForKey:@"recentSearches"];
    self.tableData = recentSearches;
    NSInteger lastSearchScopeIndex = [userDefaults integerForKey:@"lastSearchScopeIndex"];
    self.searchEngine = [[[SearchEngine alloc] init] autorelease];
    self.searchController = [[[UISearchController alloc] initWithSearchResultsController:nil] autorelease];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = false;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.scopeButtonTitles = @[@"Title", @"Document"];
    [self.searchController.searchBar setSelectedScopeButtonIndex:lastSearchScopeIndex];
    self.searchController.searchBar.delegate = self;
    self.definesPresentationContext = true;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (void) cancel {
    [self.searchDelegate searchViewControllerCancel:self];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self requestSearch];
}

- (void)requestSearch {
    if(self.searchTimer)
    {
        [self.searchTimer invalidate];
        self.searchTimer = nil;
    }
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(performSearch) userInfo:nil repeats:NO];
}

- (BOOL)isTitleSearch {
    return self.searchController.searchBar.selectedScopeButtonIndex == 0;
}

- (void)performSearch {
    NSString *queryString = [self.searchController.searchBar text];
    if ([queryString length] > 1) {
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSArray *recentSearches = [userDefaults arrayForKey:@"recentSearches"];
        if ([recentSearches containsObject:queryString] == NO) {
            NSMutableArray *newSearches= [NSMutableArray arrayWithArray:recentSearches];
            if ([newSearches count] >= 9) {
                [newSearches removeLastObject];
            }
            [newSearches insertObject:queryString atIndex:0];
            [userDefaults setObject:newSearches forKey:@"recentSearches"];
            [userDefaults synchronize];
        }
        
        NSInteger scopeIndex = self.searchController.searchBar.selectedScopeButtonIndex;
        NSString *scopeType = [self.searchController.searchBar.scopeButtonTitles objectAtIndex:scopeIndex];
        self.isSearching = YES;
        self.tableData = @[];
        [self.tableView reloadData];
        [scopeType retain];
        [queryString retain];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSArray *queryResults = [self.searchEngine query:queryString type:scopeType];
            [queryResults retain];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                self.isSearching = NO;
                [self.searchingIndicator stopAnimating];
                [self.searchingIndicator removeFromSuperview];
                self.showRecentSearches = NO;
                self.tableData = queryResults;
                [self.tableView reloadData];
                [queryResults release];
                [scopeType release];
                [queryString release];
            });
        });
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    self.showRecentSearches = YES;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *recentSearches = [userDefaults arrayForKey:@"recentSearches"];
    self.tableData = recentSearches;
    [self.tableView reloadData];
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:selectedScope forKey:@"lastSearchScopeIndex"];
    [userDefaults synchronize];
    [self requestSearch];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numOfSections = 0;
    if ([self.tableData count] > 0 || self.showRecentSearches || self.isSearching)
    {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        numOfSections = 1;
        self.tableView.backgroundView = nil;
    }
    else
    {
        UILabel *noDataLabel         = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)] autorelease];
        noDataLabel.text             = [self.searchController.searchBar.text length] > 0 ? @"No Results" : @"";
        noDataLabel.textColor        = [ThemeManager isNightMode] ? [UIColor whiteColor] : [UIColor blackColor];
        noDataLabel.textAlignment    = NSTextAlignmentCenter;
        self.tableView.backgroundView = noDataLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    
    return numOfSections;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isSearching) {
        return 1;
    }
    else {
        return [self.tableData count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"SearchCell";
    
    UITableViewCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]
                 initWithStyle:UITableViewCellStyleSubtitle
                 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *startFontTag = nil;
    if ([ThemeManager isNightMode]) {
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor whiteColor];
        startFontTag = @"<font color='white'>";
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        startFontTag = @"<font color='black'>";
    }
    
    if (self.isSearching) {
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        UIActivityIndicatorViewStyle style = [ThemeManager isNightMode] ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
        self.searchingIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style] autorelease];
        [cell.contentView addSubview:self.searchingIndicator];
        [self.searchingIndicator performSelector:@selector(startAnimating) withObject:nil afterDelay:0.25];
        self.searchingIndicator.center = cell.contentView.center;
    }
    else if (self.showRecentSearches) {
        NSString *aSearch = [self.tableData objectAtIndex:indexPath.row];
        cell.textLabel.text = aSearch;
        cell.detailTextLabel.text = nil;
        cell.detailTextLabel.attributedText = nil;
    }
    else {
        if (indexPath.row < [self.tableData count]) {
            NSDictionary *resultData = [self.tableData objectAtIndex:indexPath.row];
            [resultData retain];
            NSString *subtitle = [resultData objectForKey:@"subtitle"];
            NSString *snippet = [resultData objectForKey:@"snippet"];
            NSString *formattedSnippet = [NSString stringWithFormat:@"%@%@%@", startFontTag, snippet, @"</font>"];
            NSAttributedString * attrStr = [[[NSAttributedString alloc] initWithData:[formattedSnippet dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:nil error:nil] autorelease];
            cell.textLabel.text = [resultData objectForKey:@"title"];
            if ([self isTitleSearch] && [subtitle length] > 0) {
                cell.detailTextLabel.text = subtitle;
            }
            else {
                cell.detailTextLabel.attributedText = [self isTitleSearch] ? nil : attrStr;
            }
            
            [resultData release];
        }
    }
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.showRecentSearches ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *recentSearches = [NSMutableArray arrayWithArray:self.tableData];
        [recentSearches removeObjectAtIndex:indexPath.row];
        self.tableData = recentSearches;
        [userDefaults setObject:recentSearches forKey:@"recentSearches"];
        [userDefaults synchronize];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationRight];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.showRecentSearches) {
        NSString *aSearch = [self.tableData objectAtIndex:indexPath.row];
        self.searchController.searchBar.text = aSearch;
        [self performSearch];
    }
    else {
        NSDictionary *resultData = [self.tableData objectAtIndex:indexPath.row];
        [self.searchDelegate loadPage:[resultData objectForKey:@"filePath"]];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_searchEngine release];
    [_searchController release];
    [_tableData release];
    [_searchTimer release];
    [_searchingIndicator release];
    [super dealloc];
}


@end
