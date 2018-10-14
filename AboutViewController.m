//
//  AboutViewController.m
//  AccessToInsight
//
//  Created by Dev on 2013-07-11.
//
//

#import "AboutViewController.h"
#import "ThemeManager.h"

@interface AboutViewController ()

@property(nonatomic, retain) UITableView *tableView;

@end

@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [_tableView release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = @"About";
    
    self.tableView = [[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped] autorelease];
    [ThemeManager decorateTableView:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 11, *)) {
        UILayoutGuide * guide = self.view.safeAreaLayoutGuide;
        [self.tableView.topAnchor constraintEqualToAnchor:guide.topAnchor].active = YES;
        [self.tableView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor].active = YES;
        [self.tableView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor].active = YES;
        [self.tableView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor].active = YES;
    } else {
        UILayoutGuide *margins = self.view.layoutMarginsGuide;
        [self.tableView.topAnchor constraintEqualToAnchor:margins.topAnchor].active = YES;
        [self.tableView.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor].active = YES;
        [self.tableView.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor].active = YES;
        [self.tableView.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor].active = YES;
    }
}

#pragma mark - UITable View Delegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    else if (section == 1) {
        return 3;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SettingsTableCellId";
    
    UITableViewCell *cell = [tableView
							 dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleDefault
				 reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [ThemeManager decorateTableCell:cell];
    
    if ([indexPath section] == 0) {
        NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
        cell.textLabel.text = [NSString stringWithFormat:@"Version %@", version];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if ([indexPath section] == 1) {
        if ([indexPath row] == 0) {
            cell.textLabel.text = @"Access to Insight Website";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else if ([indexPath row] == 1) {
            cell.textLabel.text = @"Questions & Feedback";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else if ([indexPath row] == 2) {
            cell.textLabel.text = @"Info";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
	
    return cell;
}

- (void)openURL:(NSString *)urlString {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 1) {
        if ([indexPath row] == 0) {
            [self openURL:@"http://www.accesstoinsight.org/"];
        }
        else if ([indexPath row] == 1) {
            MFMailComposeViewController *mailComposer = [[[MFMailComposeViewController alloc] init] autorelease];
            mailComposer.mailComposeDelegate = self;
            [mailComposer setToRecipients:@[@"accesstoinsightapp@gmail.com"]];
            [mailComposer setSubject:[NSString stringWithFormat:@"Question about ATI %@ App", [[UIDevice currentDevice] model]]];
            [self presentViewController:mailComposer animated:YES completion:nil];
        }
        else if ([indexPath row] == 2) {
            WKWebView *infoWebView = [[[WKWebView alloc] initWithFrame:self.view.frame] autorelease];
            infoWebView.navigationDelegate = self;
            NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
            NSString *fullPath = [NSString pathWithComponents:
                                  [NSArray arrayWithObjects:resourcePath,
                                   LOCAL_WEB_DATA_DIR, @"about.html", nil]];
            NSString *readAccessPath = [NSString pathWithComponents:
                                        [NSArray arrayWithObjects:resourcePath,
                                         LOCAL_WEB_DATA_DIR, nil]];
            NSURL *url = [NSURL fileURLWithPath:fullPath];
            NSURL *readAccessURL = [NSURL fileURLWithPath:readAccessPath];
            
            [infoWebView loadFileURL:url allowingReadAccessToURL:readAccessURL];
            UIViewController *webVC = [[[UIViewController alloc] init] autorelease];
            webVC.title = @"Info";
            webVC.view = infoWebView;
            [self.navigationController pushViewController:webVC animated:YES];
        }
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSString *javascript = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
    
    [webView evaluateJavaScript:javascript completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [webView evaluateJavaScript:[ThemeManager getCSSJavascript] completionHandler:^(id result, NSError *error) {}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Mail Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
