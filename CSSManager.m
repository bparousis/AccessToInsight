//
//  CSSManager.m
//  AccessToInsight
//
//  Created by Bill Parousis on 2017-05-21.
//
//

#import "CSSManager.h"

@implementation CSSManager

+ (NSString *)getCSSJavascript {
    NSString *cssFile = IPHONE_CSS;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL nightMode = [userDefaults boolForKey:@"nightMode"];
    switch (UI_USER_INTERFACE_IDIOM()) {
        case UIUserInterfaceIdiomPad:
        {
            cssFile = nightMode ? IPAD_NIGHT_CSS : IPAD_CSS;
            break;
        }
        case UIUserInterfaceIdiomPhone:
        default:
        {
            cssFile = nightMode ? IPHONE_NIGHT_CSS : IPHONE_CSS;
            break;
        }
    }
    
    NSString *javascript = [NSString stringWithFormat:
                            @"var links = document.getElementsByTagName('link');"
                            @"for(var i = 0; i < links.length; i++) {"
                            @"if (links[i].rel === 'stylesheet') {"
                            @"var hrefString = links[i].href;"
                            @"links[i].href = hrefString.replace('screen.css', '%@');"
                            @"break;"
                            @"}}", cssFile];
    return javascript;
}

@end
