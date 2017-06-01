//
//  TextSizeViewController.m
//  AccessToInsight
//
//  Created by Dev on 2017-05-19.
//
//

#import "TextSizeViewController.h"
#import "MainViewController.h"

@interface TextSizeViewController ()

@property(nonatomic, retain) UIWebView *textSizeWebView;
@property(nonatomic, retain) UIToolbar *toolbar;

@end

@implementation TextSizeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textSizeWebView = [[[UIWebView alloc] init] autorelease];
    self.textSizeWebView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textSizeWebView.delegate = self;
    
    
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *fullPath = [NSString pathWithComponents:
                          [NSArray arrayWithObjects:resourcePath,
                           @"web_content", @"textSize.html", nil]];
    NSURL *url = [NSURL fileURLWithPath:fullPath];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
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
    
    
    [self.toolbar setItems:@[leftFlex, decreaseButton, middleFixed, increaseButton, rightFlex]];
    
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
//    self.toolbar.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
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
    [self.textSizeWebView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
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
