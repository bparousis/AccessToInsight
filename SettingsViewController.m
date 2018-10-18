//
//  SettingsViewController.m
//  AccessToInsight
//
//  Created by Bill Parousis on 2017-05-17.
//
#import "SettingsViewController.h"
#import "AboutViewController.h"
#import "TextSizeViewController.h"
#import "ThemeManager.h"

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
    [ThemeManager decorateTableView:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
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
        return 2;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SettingsTableCellId";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]
                 initWithStyle:UITableViewCellStyleDefault
                 reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [ThemeManager decorateTableCell:cell];
    
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
            nightModeSwitch.onTintColor = [UIColor colorWithRed:62.0/255.0f green:164.0/255.0f blue:242.0/255.0f alpha:1.0f];
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
    
    [ThemeManager decorateTableView:self.tableView];
    
    NSArray<UITableViewCell*> *cells = self.tableView.visibleCells;
    for (NSInteger i = 0; i < cells.count; i++) {
        [ThemeManager decorateTableCell:cells[i]];
    }
    
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

