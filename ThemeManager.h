//
//  ThemeManager.h
//  AccessToInsight
//
//  Created by Dev on 2017-06-07.
//
//

#define LOCAL_WEB_DATA_DIR	@"web_content"
#define SCREEN_CSS_PATH		@"css/screen.css"
#define IPHONE_CSS			@"iphone.css"
#define IPHONE_NIGHT_CSS	@"iphone_night.css"
#define IPAD_CSS			@"ipad.css"
#define IPAD_NIGHT_CSS	    @"ipad_night.css"

#import <Foundation/Foundation.h>

@interface ThemeManager : NSObject

+ (NSString *)getCSSJavascript;

+ (UIColor *)backgroundColor:(BOOL)nightMode;
+ (void)decorateToolbar:(UIToolbar *)toolbar nightMode:(BOOL)nightMode;
+ (void)updateStatusBarStyle:(BOOL)nightMode;

@end

