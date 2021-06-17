//
//  SearchEngine.h
//  AccessToInsight
//
//  Created by Bill Parousis on 2017-06-25.
//
//

#import <Foundation/Foundation.h>

typedef enum SearchType : NSUInteger {
    kTitle,
    kDocument
} SearchType;

@interface SearchEngine : NSObject
{
    NSString *databasePath;
}

- (NSArray<NSDictionary<NSString*, id>*> *_Nonnull)query:(NSString *_Nonnull)queryString
                                                    type:(SearchType)type;

@end
