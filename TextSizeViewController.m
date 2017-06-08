//
//  TextSizeViewController.m
//  AccessToInsight
//
//  Created by Dev on 2017-05-19.
//
//
#import <WebKit/Webkit.h>

#import "TextSizeViewController.h"
#import "MainViewController.h"
#import "ThemeManager.h"

@interface TextSizeViewController ()

@property(nonatomic, retain) WKWebView *textSizeWebView;
@property(nonatomic, retain) UIToolbar *toolbar;

@end

@implementation TextSizeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Text size";
    WKWebViewConfiguration *webConfig = [[[WKWebViewConfiguration alloc] init] autorelease];
    self.textSizeWebView = [[[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfig] autorelease];
    self.textSizeWebView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textSizeWebView.navigationDelegate = self;
    
    LocalBookmark *lastLocationBookmark = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"lastLocationBookmark"];
    if (data) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]
                                         initForReadingWithData:data];
        lastLocationBookmark = [unarchiver decodeObjectForKey:@"bookmark"];
        [unarchiver finishDecoding];
        [unarchiver release];
    }
    
    if (lastLocationBookmark != nil) {
        [self loadLocalWebContent:lastLocationBookmark.location];
    } else {
        [self loadLocalWebContent:@"index.html"];
    }
    
    self.toolbar = [[[UIToolbar alloc] init] autorelease];
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImage *increaseImage = [UIImage imageNamed:@"increase_font"];
    UIBarButtonItem *leftFlex = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem *middleFixed = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
    middleFixed.width = 35.0f;
    UIBarButtonItem *rightFlex = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem *increaseButton = [[[UIBarButtonItem alloc] initWithImage:increaseImage style:UIBarButtonItemStylePlain
                                                                       target:self action:@selector(increaseFontSize:)] autorelease];
    UIImage *decreaseImage = [UIImage imageNamed:@"decrease_font"];
    UIBarButtonItem *decreaseButton = [[[UIBarButtonItem alloc] initWithImage:decreaseImage style:UIBarButtonItemStylePlain
                                                                       target:self action:@selector(decreaseFontSize:)] autorelease];
    UIBarButtonItem *resetButton = [[[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetTextFontSize:)] autorelease];
    
    
    [self.toolbar setItems:@[leftFlex, decreaseButton, middleFixed, increaseButton, rightFlex, resetButton]];
    
    [self.view addSubview:self.textSizeWebView];
    [self.view addSubview:self.toolbar];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:44.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textSizeWebView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textSizeWebView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textSizeWebView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textSizeWebView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.toolbar
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSString *javascript = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
    
    [self.textSizeWebView evaluateJavaScript:javascript completionHandler:nil];
}

- (void)loadLocalWebContent:(NSString *)path {
    NSString *hash = nil;
    NSRange hashRange = [path rangeOfString:@"#" options:NSBackwardsSearch];
    if (hashRange.location != NSNotFound) {
        hash = [path substringFromIndex:hashRange.location];
        path = [path substringToIndex:hashRange.location];
    }
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *fullPath = [NSString pathWithComponents:
                          [NSArray arrayWithObjects:resourcePath,
                           LOCAL_WEB_DATA_DIR, path, nil]];
    NSURL *url = [NSURL fileURLWithPath:fullPath];
    if (hash) {
        url = [NSURL URLWithString:hash relativeToURL:url];
    }
    
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [self.textSizeWebView loadRequest:req];
}

- (void)increaseTextFontSize:(BOOL)increase
{
    NSUInteger textFontSize = [MainViewController textFontSize];
    
    if (increase) {
        textFontSize = (textFontSize < 160) ? textFontSize +5 : textFontSize;
    }
    else {
        textFontSize = (textFontSize > 50) ? textFontSize -5 : textFontSize;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithInteger:textFontSize] forKey:TEXT_FONT_SIZE_KEY];
    [userDefaults synchronize];
    
    [self adjustFontForWebView];
}

- (void)resetTextFontSize:(id)sender
{
    NSUInteger textFontSize = 100;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithInteger:textFontSize] forKey:TEXT_FONT_SIZE_KEY];
    [userDefaults synchronize];
    
    [self adjustFontForWebView];
}

- (void)increaseFontSize:(id)sender {
    [self increaseTextFontSize:YES];
}

- (void)decreaseFontSize:(id)sender {
    [self increaseTextFontSize:NO];
    [self.textSizeWebView reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)dealloc {
    [_textSizeWebView release];
    [_toolbar release];
    [super dealloc];
}

- (void)adjustFontForWebView {
    NSUInteger textFontSize = [MainViewController textFontSize];
    NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",
                          (unsigned long)textFontSize];
    
    [self.textSizeWebView evaluateJavaScript:jsString completionHandler:^(id result, NSError *error) {
        NSLog(@"Test");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self adjustFontForWebView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
