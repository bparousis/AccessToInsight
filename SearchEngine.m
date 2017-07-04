//
//  SearchEngine.m
//  AccessToInsight
//
//  Created by Dev on 2017-06-25.
//
//

#import "SearchEngine.h"
#import <sqlite3.h>
#import <UIKit/UIKit.h>

@interface SearchEngine ()

@property(nonatomic, retain) NSCache *searchCache;

@end

@implementation SearchEngine

static sqlite3 *database = nil;

static double rankFunc(unsigned int *aMatchinfo){
    int nCol;                       /* Number of columns in the table */
    int nPhrase;                    /* Number of phrases in the query */
    int iPhrase;                    /* Current phrase */
    double score = 0.0;             /* Value to return */
    double defaultWeight = 1.0;
    
    assert( sizeof(int)==4 );
    
    /* Check that the number of arguments passed to this function is correct.
     ** If not, jump to wrong_number_args. Set aMatchinfo to point to the array
     ** of unsigned integer values returned by FTS function matchinfo. Set
     ** nPhrase to contain the number of reportable phrases in the users full-text
     ** query, and nCol to the number of columns in the table.
     */
    nPhrase = aMatchinfo[0];
    nCol = aMatchinfo[1];
    
    /* Iterate through each phrase in the users query. */
    for(iPhrase=0; iPhrase<nPhrase; iPhrase++){
        int iCol;                     /* Current column */
        
        /* Now iterate through each column in the users query. For each column,
         ** increment the relevancy score by:
         **
         **   (<hit count> / <global hit count>) * <column weight>
         **
         ** aPhraseinfo[] points to the start of the data for phrase iPhrase. So
         ** the hit count and global hit counts for each column are found in
         ** aPhraseinfo[iCol*3] and aPhraseinfo[iCol*3+1], respectively.
         */
        unsigned int *aPhraseinfo = &aMatchinfo[2 + iPhrase*nCol*3];
        for(iCol=0; iCol<nCol; iCol++){
            int nHitCount = aPhraseinfo[3*iCol];
            int nGlobalHitCount = aPhraseinfo[3*iCol+1];
            double weight = defaultWeight;
            if( nHitCount>0 ){
                score += ((double)nHitCount / (double)nGlobalHitCount) * weight;
            }
        }
    }
    
    return score;
}

- (id)init {
    self = [super init];
    if (self) {
        self.searchCache = [[[NSCache alloc] init] autorelease];
        self.searchCache.countLimit = 9;
    }
    return self;
}

- (NSArray *)query:(NSString *)queryString {
    return [self query:queryString type:@"Document"];
}

- (NSArray *)query:(NSString *)queryString type:(NSString *)type {
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@", queryString, type];
    NSArray *cacheResults = [self.searchCache objectForKey:cacheKey];
    if (cacheResults != nil) {
        return cacheResults;
    }
    
    int searchTextCol = 1;
    NSString *searchColumn = @"Page";
    if ([type isEqualToString:@"Title"]) {
        searchTextCol = 0;
        searchColumn = @"title";
    }
    NSString *searchSQL = [NSString stringWithFormat:@"SELECT title, subtitle, snippet(Page), filePath, matchinfo(Page) FROM Page WHERE %@ MATCH ?", searchColumn];
    const char *sql = [searchSQL UTF8String];
    sqlite3_stmt *sqlStmt;
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    databasePath = [NSString pathWithComponents:
                    [NSArray arrayWithObjects:resourcePath,
                     @"pages.db", nil]];
    NSMutableArray *allResults = [NSMutableArray array];
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        int resp =sqlite3_prepare_v2(database, sql , -1, &sqlStmt, NULL);
        if (resp == SQLITE_OK) {
            sqlite3_bind_text(sqlStmt, 1, [queryString UTF8String], -1, 0);
            while(sqlite3_step(sqlStmt)==SQLITE_ROW){
                NSString *title = [NSString stringWithUTF8String:(char *) sqlite3_column_text(sqlStmt, 0)];
                char *subtitleChar = (char *)sqlite3_column_text(sqlStmt, 1);
                NSString *subtitle = nil;
                if (subtitleChar != NULL) {
                    subtitle = [NSString stringWithUTF8String: subtitleChar];
                }
                NSString *snippet = [NSString stringWithUTF8String:(char *) sqlite3_column_text(sqlStmt, 2)];
                NSString *filePath = [NSString stringWithUTF8String:(char *) sqlite3_column_text(sqlStmt, 3)];
                unsigned int *aMatchinfo = (unsigned int *)sqlite3_column_blob(sqlStmt, 4);
                double rank = rankFunc(aMatchinfo);
                NSNumber *rankNum = [NSNumber numberWithDouble:rank];
                NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObjects:@[title, snippet, filePath, rankNum]
                                                                                 forKeys:@[@"title", @"snippet", @"filePath", @"rank"]];
                if (subtitle != nil) {
                    [result setObject:subtitle forKey:@"subtitle"];
                }
                [allResults addObject:result];
            }
            sqlite3_finalize(sqlStmt);
        }
    }
    sqlite3_close(database);
    if ([allResults count] > 0) {
        NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"rank"
                                                                     ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
        NSArray *sortedArray = [allResults sortedArrayUsingDescriptors:sortDescriptors];
        [self.searchCache setObject:sortedArray forKey:cacheKey];
        return sortedArray;
    }
    else {
        [self.searchCache setObject:@[] forKey:cacheKey];
        return @[];
    }
}

- (void) dealloc {
    [_searchCache release];
    
    [super dealloc];
}

@end
