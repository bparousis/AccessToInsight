//
//  SearchEngine.m
//  AccessToInsight
//
//  Created by Bill Parousis on 2017-06-25.
//
//

#import "LegacySearchEngine.h"
#import <sqlite3.h>
#import "rank.h"
#import <UIKit/UIKit.h>

@interface LegacySearchEngine ()

@property(nonatomic, strong) NSCache *searchCache;

@end

@implementation LegacySearchEngine

static sqlite3 *database = nil;

- (id)init {
    self = [super init];
    if (self) {
        self.searchCache = [[NSCache alloc] init];
        self.searchCache.countLimit = 9;
    }
    return self;
}

- (NSArray<NSDictionary<NSString*, id>*> *_Nonnull)query:(NSString *_Nonnull)queryString type:(SearchType)type
{
    NSString *cacheKey = [NSString stringWithFormat:@"%@%d", queryString, (int)type];
    NSArray *cacheResults = [self.searchCache objectForKey:cacheKey];
    if (cacheResults != nil) {
        return cacheResults;
    }
    
    NSString *searchColumn = type == kTitle ? @"title" : @"Page";
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
                
                NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:
                                               @{@"title": title, @"snippet": snippet, @"filePath": filePath, @"rank": rankNum}];
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

@end
