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
    switch (UI_USER_INTERFACE_IDIOM()) {
        case UIUserInterfaceIdiomPad:
        {
            cssFile = [ThemeManager isNightMode] ? IPAD_NIGHT_CSS : IPAD_CSS;
            break;
        }
        case UIUserInterfaceIdiomPhone:
        default:
        {
            cssFile = [ThemeManager isNightMode] ? IPHONE_NIGHT_CSS : IPHONE_CSS;
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

+ (UIColor *)backgroundColor {
    return [ThemeManager isNightMode] ? [UIColor colorWithRed:39.0/255.0f green:40.0/255.0f blue:34.0/255.0f alpha:1.0f] : [UIColor whiteColor];
}

+ (void)decorateToolbar:(UIToolbar *)toolbar {
    toolbar.translucent = YES;
    if ([ThemeManager isNightMode]) {
        toolbar.barTintColor = [ThemeManager backgroundColor];
        toolbar.tintColor = [UIColor colorWithRed:227.0/255.0f green:227.0/255.0f blue:227.0/255.0f alpha:1.0f];
    }
    else {
        toolbar.barTintColor = nil;
        toolbar.tintColor = nil;
    }
}

+ (void)decorateTableView:(UITableView *)tableView {
    if ([ThemeManager isNightMode]) {
        tableView.backgroundColor = [ThemeManager backgroundColor];
    }
    else {
        UITableView *aTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tableView.backgroundColor = aTableView.backgroundColor;
        [aTableView release];
    }
}

+ (void)decorateTableCell:(UITableViewCell *)cell {
    if ([ThemeManager isNightMode]) {
        cell.backgroundColor = [UIColor colorWithRed:68.0/255.0f green:68.0/255.0f blue:68.0/255.0f alpha:1.0f];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor whiteColor];
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
}

+ (BOOL)isNightMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"nightMode"];
}

@end
