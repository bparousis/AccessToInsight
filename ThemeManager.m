//
//  ThemeManager.m
//  AccessToInsight
//
//  Created by Dev on 2017-06-07.
//
//

#import "ThemeManager.h"

@implementation ThemeManager

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

+ (UIColor *)backgroundColor:(BOOL)nightMode {
    return nightMode ? [UIColor colorWithRed:39.0/255.0f green:40.0/255.0f blue:34.0/255.0f alpha:1.0f] : [UIColor whiteColor];
}

+ (void)decorateToolbar:(UIToolbar *)toolbar nightMode:(BOOL)nightMode {
    toolbar.translucent = YES;
    if (nightMode) {
        toolbar.barTintColor = [ThemeManager backgroundColor:nightMode];
        toolbar.tintColor = [UIColor colorWithRed:227.0/255.0f green:227.0/255.0f blue:227.0/255.0f alpha:1.0f];
    }
    else {
        toolbar.barTintColor = nil;
        toolbar.tintColor = nil;
    }
}

+ (void)updateStatusBarStyle:(BOOL)nightMode {
    [[UIApplication sharedApplication] setStatusBarStyle:(nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault)];
}

@end
