//
//  CSSManager.h
//  AccessToInsight
//
//  Created by Dev on 2017-05-21.
//
//

#define LOCAL_WEB_DATA_DIR	@"web_content"
#define SCREEN_CSS_PATH		@"css/screen.css"
#define IPHONE_CSS			@"iphone.css"
#define IPHONE_NIGHT_CSS	@"iphone_night.css"
#define IPAD_CSS			@"ipad.css"
#define IPAD_NIGHT_CSS	    @"ipad_night.css"

#import <Foundation/Foundation.h>

@interface CSSManager : NSObject

+ (NSString *)getCSSJavascript;

@end
