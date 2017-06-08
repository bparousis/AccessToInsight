//
//  SettingsViewController.m
//  AccessToInsight
//
//  Created by Dev on 2017-05-17.
//
#import "SettingsViewController.h"
#import "AboutViewController.h"
#import "TextSizeViewController.h"

@interface SettingsViewController ()

@property(nonatomic, retain) UITableView *tableView;

@end

@implementation SettingsViewController

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
    self.title = @"Settings";
    self.tableView = [[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped] autorelease];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizesSubviews = YES;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.frame = self.view.frame;
}

#pragma mark - UITable View Delegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    else if (section == 1) {
        return 2;
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
    
    if ([indexPath section] == 0) {
        cell.textLabel.text = @"About";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([indexPath section] == 1) {
        if ([indexPath row] == 0) {
            cell.textLabel.text = @"Text Size";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else if ([indexPath row] == 1) {
            cell.textLabel.text = @"Night Mode";
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            BOOL nightMode = [userDefaults boolForKey:@"nightMode"];
            UISwitch *nightModeSwitch = [[[UISwitch alloc] init] autorelease];
            nightModeSwitch.on = nightMode;
            [nightModeSwitch addTarget:self action:@selector(nightModeToggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = nightModeSwitch;
        }
    }
    
    return cell;
}

- (void)nightModeToggled:(id)sender {
    BOOL nightMode = [sender isOn];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:nightMode forKey:@"nightMode"];
    [userDefaults synchronize];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NightMode"
     object:self];
}

- (void)openURL:(NSString *)urlString {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            AboutViewController *aboutVC = [[[AboutViewController alloc] init] autorelease];
            [self.navigationController pushViewController:aboutVC animated:YES];
        }
    }
    if ([indexPath section] == 1) {
        if ([indexPath row] == 0) {
            TextSizeViewController *textSizeVC = [[[TextSizeViewController alloc] init] autorelease];
            [self.navigationController pushViewController:textSizeVC animated:YES];
        }
    }
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

