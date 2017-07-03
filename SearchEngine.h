//
//  SearchEngine.h
//  AccessToInsight
//
//  Created by Dev on 2017-06-25.
//
//

#import <Foundation/Foundation.h>

@interface SearchEngine : NSObject
{
    NSString *databasePath;
}

- (void)setup;
- (NSArray *)query:(NSString *)queryString;
- (NSArray *)query:(NSString *)queryString type:(NSString *)type;

@end
