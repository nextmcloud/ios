//
//  NCSettings.m
//  Nextcloud
//
//  Created by Marino Faggiana on 24/11/14.
//  Copyright (c) 2014 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "NCSettings.h"
#import "CCAdvanced.h"
#import "CCManageAccount.h"
#import "CCManageAutoUpload.h"
#import "NCBridgeSwift.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <TOPasscodeViewController/TOPasscodeViewController.h>
//#import <TOPasscodeViewController/TOPasscodeViewController.h>

#define alertViewEsci 1
#define alertViewAzzeraCache 2

@interface NCSettings () <TOPasscodeSettingsViewControllerDelegate, TOPasscodeViewControllerDelegate>
{
    AppDelegate *appDelegate;
    TOPasscodeViewController *passcodeViewController;
    TOPasscodeSettingsViewController *passcodeSettingsViewController;

    NSString *versionServer;
    NSString *themingName;
    NSString *themingSlogan;
}
@end

@implementation NCSettings

- (void)initializeForm
{
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;

    form.rowNavigationOptions = XLFormRowNavigationOptionNone;
    
    // Section AUTO UPLOAD OF CAMERA IMAGES ----------------------------
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"autoUpload" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_settings_autoupload_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    [row.cellConfig setObject:[[UIImage imageNamed:@"autoUpload"] imageWithColor:NCBrandColor.shared.iconColor size:25] forKey:@"imageView.image"];
    row.action.viewControllerClass = [CCManageAutoUpload class];
    [section addFormRow:row];

    // Section : SECURITY --------------------------------------------------------------
    
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"_security_", nil)];
    [form addFormSection:section];

    // Lock active YES/NO
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"bloccopasscode" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_lock_not_active_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[[UIImage imageNamed:@"lock_open"] imageWithColor:NCBrandColor.shared.iconColor size:25] forKey:@"imageView.image"];
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    //[row.cellConfig setObject:@(UITableViewCellAccessoryDisclosureIndicator) forKey:@"accessoryType"];
    row.action.formSelector = @selector(passcode:);
    [section addFormRow:row];
    // Enable Touch ID
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"enableTouchDaceID" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"_enable_touch_face_id_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    row.cellConfig[@"switchControl.onTintColor"] = NCBrandColor.shared.brand;
    if([[NCKeychain alloc] init].passcode){
        row.disabled = @NO;
    }else{
        row.disabled = @YES;
    }
    [section addFormRow:row];

    // Section : E2EEncryption --------------------------------------------------------------

    BOOL isE2EEEnabled = [[NCGlobal shared] capabilityE2EEEnabled];
    NSString *versionE2EE = [[NCGlobal shared] capabilityE2EEApiVersion];

    if (isE2EEEnabled == YES && [NCGlobal.shared.e2eeVersions containsObject:versionE2EE]) {

        // EndToEnd Encryption
        NSString *title = [NSString stringWithFormat:@"%@",NSLocalizedString(@"_e2e_settings_", nil)];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"e2eEncryption" rowType:XLFormRowDescriptorTypeButton title:title];
        row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
        [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
        [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
        [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
        [row.cellConfig setObject:[[UIImage imageNamed:@"lock"] imageWithColor:NCBrandColor.shared.iconColor size:25] forKey:@"imageView.image"];
        row.action.formSelector = @selector(manageE2EE:);
        [section addFormRow:row];
    }

    // Section Advanced -------------------------------------------------
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // Advanced
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"advanced" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_advanced_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    [row.cellConfig setObject:[[UIImage imageNamed:@"gear"] imageWithColor:NCBrandColor.shared.iconColor size:25] forKey:@"imageView.image"];
    row.action.viewControllerClass = [CCAdvanced class];
    [section addFormRow:row];

    // Section : DATA PROTECTION ------------------------------------------------

    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"_data_protection_", nil)];
    [form addFormSection:section];
    
    // Privacy Settings
    PrivacySettingsViewController *privacySettingsViewController = [[PrivacySettingsViewController alloc] init];
    privacySettingsViewController.isShowSettingsButton = true;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showSettingsButton"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"privacySettings" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_privacy_settings_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    row.action.viewControllerClass = [privacySettingsViewController class];
    [section addFormRow:row];

    // Privacy Policy
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"advanced" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_privacy_policy_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    row.action.viewControllerClass = [PrivacyPolicyViewController class];
    [section addFormRow:row];
    
    // Used OpenSource Software
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"buttonLeftAligned" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_used_opensource_software_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    row.action.viewControllerClass = [OpenSourceSoftwareViewController class];
    [section addFormRow:row];
    
    
    // Section : SERVICE ------------------------------------------------

    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"_service_", nil)];
    [form addFormSection:section];

    // HELP
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"buttonLeftAligned" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_help_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    row.action.viewControllerClass = [HelpViewController class];
    [section addFormRow:row];

    // Imprint
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"buttonLeftAligned" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_imprint_", nil)];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"textLabel.font"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"textLabel.textColor"];
    row.action.viewControllerClass = [ImprintViewController class];
    [section addFormRow:row];

    // Section : INFO ------------------------------------------------

    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"_info_", nil)];
    [form addFormSection:section];

    //MagentaCloud Version

    //custom cell

    [[XLFormViewController cellClassesForRowDescriptorTypes] setObject:[MagentaCloudVersionView class] forKey:@"kNMCCustomCellType"];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"disablefilesapp" rowType:@"kNMCCustomCellType" title:NSLocalizedString(@"_magentacloud_version_", nil)];
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleInfoDictionaryVersion"];
    row.cellConfigAtConfigure[@"backgroundColor"] = UIColor.secondarySystemGroupedBackgroundColor;
    row.cellConfigAtConfigure[@"cellLabel.text"] = NSLocalizedString(@"_magentacloud_version_", nil);
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"cellLabel.font"];
    [row.cellConfig setObject:UIColor.labelColor forKey:@"cellLabel.textColor"];
    row.cellConfigAtConfigure[@"versionLabel.text"] = appVersion;
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0] forKey:@"versionLabel.font"];
    [row.cellConfig setObject:UIColor.systemGrayColor forKey:@"versionLabel.textColor"];
    [section addFormRow:row];
    
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 35, 0);
    self.form = form;
}

// MARK: - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"_settings_", nil);
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:NCGlobal.shared.notificationCenterApplicationDidEnterBackground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeUser) name:NCGlobal.shared.notificationCenterInitialize object:nil];

    [self initializeForm];
    [self reloadForm];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    appDelegate.activeViewController = self;

    versionServer = [[NCGlobal shared] capabilityServerVersion];
    themingName = [[NCGlobal shared] capabilityThemingName];
    themingSlogan = [[NCGlobal shared] capabilityThemingSlogan];
}

#pragma mark - NotificationCenter

- (void)changeUser
{
    [self initializeForm];
    [self reloadForm];
}

- (void)applicationDidEnterBackground
{
    if (passcodeViewController.view.window != nil) {
        [passcodeViewController dismissViewControllerAnimated:true completion:nil];
    }
    if (passcodeSettingsViewController.view.window != nil) {
        [passcodeSettingsViewController dismissViewControllerAnimated:true completion:nil];
    }

    [[self navigationController] popToRootViewControllerAnimated:false];
}

#pragma mark -

- (void)reloadForm
{
    self.form.delegate = nil;
    
    // ------------------------------------------------------------------

    XLFormRowDescriptor *rowBloccoPasscode = [self.form formRowWithTag:@"bloccopasscode"];
    XLFormRowDescriptor *rowNotPasscodeAtStart = [self.form formRowWithTag:@"notPasscodeAtStart"];
    XLFormRowDescriptor *rowEnableTouchDaceID = [self.form formRowWithTag:@"enableTouchDaceID"];

    // ------------------------------------------------------------------
    
    if ([[NCKeychain alloc] init].passcode) {
        rowBloccoPasscode.title = NSLocalizedString(@"_lock_active_", nil);
        [rowBloccoPasscode.cellConfig setObject:[[UIImage imageNamed:@"lock"] imageWithColor:NCBrandColor.shared.iconColor size:25] forKey:@"imageView.image"];
        rowEnableTouchDaceID.disabled = @NO;
        rowNotPasscodeAtStart.disabled = @NO;
    } else {
        rowBloccoPasscode.title = NSLocalizedString(@"_lock_not_active_", nil);
        [rowBloccoPasscode.cellConfig setObject:[[UIImage imageNamed:@"lock_open"] imageWithColor:NCBrandColor.shared.iconColor size:25] forKey:@"imageView.image"];
        rowEnableTouchDaceID.disabled = @YES;
        rowNotPasscodeAtStart.disabled = @YES;
    }
    
    if ([[NCKeychain alloc] init].touchFaceID) [rowEnableTouchDaceID setValue:@1]; else [rowEnableTouchDaceID setValue:@0];
    if ([[NCKeychain alloc] init].requestPasscodeAtStart) [rowNotPasscodeAtStart setValue:@0]; else [rowNotPasscodeAtStart setValue:@1];


    // -----------------------------------------------------------------
    
    [self.tableView reloadData];
    
    self.form.delegate = self;
}

- (void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{
    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    
    if ([rowDescriptor.tag isEqualToString:@"notPasscodeAtStart"]) {
        
        if ([[rowDescriptor.value valueData] boolValue] == YES) {
            [[NCKeychain alloc] init].requestPasscodeAtStart = false;
        } else {
            [[NCKeychain alloc] init].requestPasscodeAtStart = true;
        }
    }
    
    if ([rowDescriptor.tag isEqualToString:@"enableTouchDaceID"]) {
        
        if ([[rowDescriptor.value valueData] boolValue] == YES) {
            [[NCKeychain alloc] init].touchFaceID = true;
        } else {
            [[NCKeychain alloc] init].touchFaceID = false;
        }
    }
}

#pragma mark -

- (void)manageE2EE:(XLFormRowDescriptor *)sender
{
    [self deselectFormRow:sender];

    UIViewController *vc = [[NCManageE2EEInterface alloc] makeShipDetailsUIWithAccount:appDelegate.account];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Passcode

- (void)didPerformBiometricValidationRequestInPasscodeViewController:(TOPasscodeViewController *)passcodeViewController
{
    [[LAContext new] evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:[[NCBrandOptions shared] brand] reply:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
                [[NCKeychain alloc] init].passcode = nil;
                [passcodeViewController dismissViewControllerAnimated:YES completion:nil];
                [self reloadForm];
            });
        }
    }];
}

- (void)passcodeSettingsViewController:(TOPasscodeSettingsViewController *)passcodeSettingsViewController didChangeToNewPasscode:(NSString *)passcode ofType:(TOPasscodeType)type
{
    [[NCKeychain alloc] init].passcode = passcode;
    [passcodeSettingsViewController dismissViewControllerAnimated:YES completion:nil];
    
    [self reloadForm];
}

- (void)didTapCancelInPasscodeViewController:(TOPasscodeViewController *)passcodeViewController
{
    [passcodeViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)passcodeViewController:(TOPasscodeViewController *)passcodeViewController isCorrectCode:(NSString *)code
{
    if ([code isEqualToString:[[NCKeychain alloc] init].passcode]) {
        [[NCKeychain alloc] init].passcode = nil;
        [self reloadForm];
        
        return YES;
    }
         
    return NO;
}

- (void)passcode:(XLFormRowDescriptor *)sender
{
    LAContext *laContext = [LAContext new];
    NSError *error;
    
    [self deselectFormRow:sender];

    if ([[NCKeychain alloc] init].passcode) {

        passcodeViewController = [[TOPasscodeViewController alloc] initPasscodeType:TOPasscodeTypeSixDigits allowCancel:true];
        passcodeViewController.delegate = self;
        passcodeViewController.keypadButtonShowLettering = false;

        if ([[NCKeychain alloc] init].touchFaceID && [laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            if (error == NULL) {
                if (laContext.biometryType == LABiometryTypeFaceID) {
                    passcodeViewController.biometryType = TOPasscodeBiometryTypeFaceID;
                    passcodeViewController.allowBiometricValidation = true;
                    passcodeViewController.automaticallyPromptForBiometricValidation = true;
                } else if (laContext.biometryType == LABiometryTypeTouchID) {
                    passcodeViewController.biometryType = TOPasscodeBiometryTypeTouchID;
                    passcodeViewController.allowBiometricValidation = true;
                    passcodeViewController.automaticallyPromptForBiometricValidation = true;
                } else {
                    NSLog(@"No Biometric support");
                }
            }
        }

        [self presentViewController:passcodeViewController animated:YES completion:nil];

    } else {
     
        passcodeSettingsViewController = [[TOPasscodeSettingsViewController alloc] init];
        passcodeSettingsViewController.hideOptionsButton = YES;
        passcodeSettingsViewController.requireCurrentPasscode = NO;
        passcodeSettingsViewController.passcodeType = TOPasscodeTypeSixDigits;
        passcodeSettingsViewController.delegate = self;

        [self presentViewController:passcodeSettingsViewController animated:YES completion:nil];
    }
}

#pragma mark -

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCGlobal.shared.heightCellSettings;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *sectionName;
    NSInteger numSections = [tableView numberOfSections] - 1;

    return sectionName;
}

@end
